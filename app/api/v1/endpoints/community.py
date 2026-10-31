from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.community import CommunityStory
from app.models.user import User
from app.schemas.community import StoryCreate, StoryResponse, StoryModeration
from app.services.pii_redactor import PiiRedactor
from app.api.v1.endpoints.auth import get_current_user

router = APIRouter()


@router.post("/stories", response_model=StoryResponse, status_code=status.HTTP_201_CREATED)
def submit_story(
    story_in: StoryCreate,
    db: Session = Depends(get_db)
):
    """
    Gửi câu chuyện chia sẻ hoặc tình huống lừa đảo ẩn danh.
    Bộ lọc PiiRedactor tự động nhận diện và che mờ CCCD, SĐT, STK trước khi lưu.
    """
    redacted_content, detected_pii = PiiRedactor.redact(story_in.content)

    new_story = CommunityStory(
        title=story_in.title,
        raw_content=story_in.content,
        redacted_content=redacted_content,
        scam_type=story_in.scam_type,
        reported_scammer_phone=story_in.reported_scammer_phone,
        reported_scammer_bank=story_in.reported_scammer_bank,
        reported_scammer_url=story_in.reported_scammer_url,
        loss_amount=story_in.loss_amount,
        status="approved"  # Tự động phê duyệt sau khi đã che mờ PII
    )
    db.add(new_story)
    db.commit()
    db.refresh(new_story)
    return new_story


@router.get("/stories", response_model=List[StoryResponse])
def get_public_stories(
    scam_type: Optional[str] = None,
    limit: int = Query(20, ge=1, le=100),
    skip: int = Query(0, ge=0),
    db: Session = Depends(get_db)
):
    """Lấy danh sách các câu chuyện cảnh báo đã được duyệt và che mờ thông tin cá nhân."""
    query = db.query(CommunityStory).filter(CommunityStory.status == "approved")
    if scam_type:
        query = query.filter(CommunityStory.scam_type == scam_type)
    
    return query.order_by(CommunityStory.created_at.desc()).offset(skip).limit(limit).all()


@router.post("/stories/{story_id}/upvote")
def upvote_story(story_id: int, db: Session = Depends(get_db)):
    """Ghi nhận lượt đánh giá hữu ích cho câu chuyện cảnh báo."""
    story = db.query(CommunityStory).filter(CommunityStory.id == story_id).first()
    if not story:
        raise HTTPException(status_code=404, detail="Không tìm thấy bài viết chia sẻ")
    story.upvotes += 1
    db.commit()
    return {"message": "Đã ghi nhận tương tác hữu ích", "upvotes": story.upvotes}


@router.put("/stories/{story_id}/moderate", response_model=StoryResponse)
def moderate_story(
    story_id: int,
    mod_data: StoryModeration,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Điểm cuối dành cho Quản trị viên / Kiểm duyệt viên duyệt hoặc từ chối bài viết."""
    if current_user.role not in ("admin", "moderator"):
        raise HTTPException(status_code=403, detail="Chỉ Quản trị viên mới có quyền kiểm duyệt bài")

    story = db.query(CommunityStory).filter(CommunityStory.id == story_id).first()
    if not story:
        raise HTTPException(status_code=404, detail="Bài viết không tồn tại")

    story.status = mod_data.status
    story.moderation_notes = mod_data.moderation_notes
    story.moderated_by = current_user.id
    db.commit()
    db.refresh(story)
    return story
