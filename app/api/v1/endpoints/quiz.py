from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.quiz import QuizQuestion, QuizOption, UserQuizResult
from app.models.user import User
from app.schemas.quiz import (
    QuizQuestionResponse,
    QuizSubmitRequest,
    QuizSubmitResponse,
    QuizResultDetail
)

router = APIRouter()

# Bộ câu hỏi tình huống mô phỏng thực tế rèn luyện kỹ năng phòng ngừa lừa đảo trực tuyến
SEED_QUESTIONS = [
    {
        "category": "banking",
        "scenario_title": "Tin nhắn mạo danh ngân hàng khóa thẻ",
        "scenario_description": "Bạn nhận được tin nhắn SMS Brandname từ ngân hàng với nội dung: 'Tài khoản của quý khách bị khóa do giao dịch bất thường. Nhấp vào http://vietc0mbank-portal.xyz/login để xác thực mã OTP trong vòng 2 giờ.' Bạn nên làm gì?",
        "explanation": "Tên miền 'vietc0mbank-portal.xyz' là tên miền mạo danh (Typosquatting thay chữ 'o' bằng số '0' và đuôi '.xyz'). Ngân hàng không bao giờ gửi link yêu cầu nhập mã OTP.",
        "difficulty": "medium",
        "options": [
            ("Lập tức nhấp vào link để đăng nhập và hủy giao dịch lạ", False),
            ("Nhập mã OTP nhưng không nhập mật khẩu tài khoản", False),
            ("Tuyệt đối không nhấp link, xóa tin nhắn và gọi ngay tổng đài chính thức của ngân hàng để tra cứu", True),
            ("Chuyển toàn bộ tiền sang tài khoản người thân qua link đó", False)
        ]
    },
    {
        "category": "job_scam",
        "scenario_title": "Tuyển dụng cộng tác viên giật đơn Shopee",
        "scenario_description": "Một tài khoản Zalo lạ nhắn tin mời bạn làm cộng tác viên xử lý đơn hàng trên sàn thương mại điện tử với mức hoa hồng 15-20%/đơn, yêu cầu bạn nạp trước 500.000 VNĐ tiền cọc vào tài khoản cá nhân. Đây là hình thức gì?",
        "explanation": "Đây là chiêu trò bẫy cộng tác viên nhiệm vụ điển hình. Sau các đơn nhỏ được hoàn tiền thật, kẻ gian sẽ yêu cầu nạp số tiền lớn hàng chục triệu rồi khóa liên lạc chiếm đoạt.",
        "difficulty": "easy",
        "options": [
            ("Lừa đảo chiếm đoạt tài sản bằng thủ đoạn làm nhiệm vụ hoa hồng ảo", True),
            ("Công việc bán thời gian kiếm thêm thu nhập uy tín", False),
            ("Chương trình kích cầu người dùng chính thức của sàn thương mại điện tử", False),
            ("Cơ hội đầu tư rủi ro thấp", False)
        ]
    },
    {
        "category": "impersonation",
        "scenario_title": "Cuộc gọi video Deepfake mượn tiền",
        "scenario_description": "Bạn thân của bạn gọi video qua Facebook Messenger mượn gấp 10 triệu đồng để cấp cứu. Hình ảnh khuôn mặt giật cục, âm thanh hơi méo và tắt máy sau 5 giây vì 'mạng yếu', sau đó gửi số tài khoản tên người khác. Bạn nên làm gì?",
        "explanation": "Kẻ gian thường chiếm quyền điều khiển tài khoản và sử dụng AI Deepfake tạo video ngắn giả mạo người thân rồi đưa STK người lạ. Luôn gọi điện trực tiếp bằng số di động thông thường để xác minh trước khi chuyển tiền.",
        "difficulty": "hard",
        "options": [
            ("Chuyển khoản ngay vì đã thấy mặt bạn thân trên màn hình", False),
            ("Gọi điện thoại trực tiếp qua số di động cá nhân của bạn để kiểm tra danh tính", True),
            ("Chuyển trước 5 triệu để đỡ áp lực", False),
            ("Gửi thông tin thẻ tín dụng của mình cho bạn tự rút", False)
        ]
    }
]


@router.get("/questions", response_model=List[QuizQuestionResponse])
def get_quiz_questions(db: Session = Depends(get_db)):
    """Lấy danh sách các câu hỏi tình huống trắc nghiệm nhận diện lừa đảo."""
    questions = db.query(QuizQuestion).all()

    # Nếu cơ sở dữ liệu chưa có câu hỏi nào, tự động nạp các tình huống mẫu
    if not questions:
        for item in SEED_QUESTIONS:
            q = QuizQuestion(
                category=item["category"],
                scenario_title=item["scenario_title"],
                scenario_description=item["scenario_description"],
                explanation=item["explanation"],
                difficulty=item["difficulty"]
            )
            db.add(q)
            db.flush()
            for opt_text, is_corr in item["options"]:
                opt = QuizOption(
                    question_id=q.id,
                    option_text=opt_text,
                    is_correct=is_corr
                )
                db.add(opt)
        db.commit()
        questions = db.query(QuizQuestion).all()

    return questions


@router.post("/submit", response_model=QuizSubmitResponse)
def submit_quiz_attempt(
    submission: QuizSubmitRequest,
    db: Session = Depends(get_db)
):
    """
    Chấm điểm bài thi trắc nghiệm tình huống, cung cấp lời giải thích giáo dục chi tiết và lưu nhật ký cảm xúc.
    """
    total = len(submission.answers)
    if total == 0:
        raise HTTPException(status_code=400, detail="Không có câu trả lời nào được gửi lên")

    correct_count = 0
    details = []

    for item in submission.answers:
        q = db.query(QuizQuestion).filter(QuizQuestion.id == item.question_id).first()
        if not q:
            continue

        selected_opt = db.query(QuizOption).filter(QuizOption.id == item.selected_option_id).first()
        is_corr = selected_opt.is_correct if selected_opt else False

        if is_corr:
            correct_count += 1

        correct_opt = db.query(QuizOption).filter(
            QuizOption.question_id == q.id,
            QuizOption.is_correct == True
        ).first()

        details.append(QuizResultDetail(
            question_id=q.id,
            scenario_title=q.scenario_title,
            is_correct=is_corr,
            correct_option_id=correct_opt.id if correct_opt else 0,
            explanation=q.explanation
        ))

    score_pct = int((correct_count / total) * 100) if total > 0 else 0

    return QuizSubmitResponse(
        total_questions=total,
        correct_answers=correct_count,
        score_percentage=score_pct,
        emotion_feedback=submission.emotion_feedback,
        details=details
    )
