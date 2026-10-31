from typing import List, Optional
from pydantic import BaseModel


class QuizOptionResponse(BaseModel):
    id: int
    option_text: str

    class Config:
        from_attributes = True


class QuizQuestionResponse(BaseModel):
    id: int
    category: str
    scenario_title: str
    scenario_description: str
    difficulty: str
    options: List[QuizOptionResponse]

    class Config:
        from_attributes = True


class QuizSubmissionItem(BaseModel):
    question_id: int
    selected_option_id: int


class QuizSubmitRequest(BaseModel):
    answers: List[QuizSubmissionItem]
    emotion_feedback: Optional[str] = "cautious"  # confident, cautious, anxious, alert


class QuizResultDetail(BaseModel):
    question_id: int
    scenario_title: str
    is_correct: bool
    correct_option_id: int
    explanation: str


class QuizSubmitResponse(BaseModel):
    total_questions: int
    correct_answers: int
    score_percentage: int
    emotion_feedback: Optional[str]
    details: List[QuizResultDetail]
