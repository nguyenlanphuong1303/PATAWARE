from datetime import datetime
from sqlalchemy import Column, Integer, String, Text, Boolean, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from app.core.database import Base


class QuizQuestion(Base):
    """Bảng câu hỏi tình huống mô phỏng thực tế rèn luyện kỹ năng phòng chống lừa đảo (Gamification)."""
    __tablename__ = "quiz_questions"

    id = Column(Integer, primary_key=True, index=True)
    category = Column(String(50), default="general")  # Chủ đề: 'phishing', 'banking', 'job_scam', 'crypto'
    scenario_title = Column(String(200), nullable=False)
    scenario_description = Column(Text, nullable=False)
    explanation = Column(Text, nullable=False)        # Phần giải thích kiến thức chi tiết sau khi nộp bài
    difficulty = Column(String(20), default="medium") # Độ khó: easy, medium, hard
    created_at = Column(DateTime, default=datetime.utcnow)

    options = relationship("QuizOption", back_populates="question", cascade="all, delete-orphan")


class QuizOption(Base):
    """Bảng các lựa chọn đáp án cho từng câu hỏi tình huống."""
    __tablename__ = "quiz_options"

    id = Column(Integer, primary_key=True, index=True)
    question_id = Column(Integer, ForeignKey("quiz_questions.id", ondelete="CASCADE"), nullable=False)
    option_text = Column(String(255), nullable=False)
    is_correct = Column(Boolean, default=False, nullable=False)  # Đáp án đúng hay sai

    question = relationship("QuizQuestion", back_populates="options")


class UserQuizResult(Base):
    """Bảng lưu trữ kết quả làm bài trắc nghiệm và nhật ký cảm xúc của người dùng."""
    __tablename__ = "user_quiz_results"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    total_questions = Column(Integer, nullable=False)
    correct_answers = Column(Integer, nullable=False)
    score_percentage = Column(Integer, nullable=False)
    emotion_feedback = Column(String(50), nullable=True)  # Cảm xúc ghi nhận: confident (tự tin), cautious (thận trọng), anxious (lo lắng)
    completed_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="quiz_results")
