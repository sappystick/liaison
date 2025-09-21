import os
import asyncio
import json
from flask import Flask, request, jsonify, Response
from flask_cors import CORS
from flask_socketio import SocketIO, emit, join_room, leave_room
import redis
import uuid
from datetime import datetime

app = Flask(__name__)
CORS(app, origins="*")
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='threading')

# Redis for session management
r = redis.Redis(host=os.environ.get('REDIS_HOST', 'localhost'), port=6379, db=2)

class VoiceChatHandler:
    def __init__(self):
        self.active_sessions = {}
        
    def create_session(self, user_id, agent_id):
        """Create new voice chat session"""
        session_id = str(uuid.uuid4())
        session_data = {
            "session_id": session_id,
            "user_id": user_id,
            "agent_id": agent_id,
            "created_at": datetime.utcnow().isoformat(),
            "status": "active"
        }
        
        self.active_sessions[session_id] = session_data
        r.setex(f"voice_session:{session_id}", 3600, json.dumps(session_data))
        
        return session_id
    
    def process_audio(self, audio_data, session_id):
        """Process audio input and return text transcription"""
        try:
            # Simulate speech-to-text processing
            # In production, integrate with Google Cloud Speech or Azure Speech
            transcript = "Hello, how can I help you today?"
            confidence = 0.95
            
            return {
                "transcript": transcript,
                "confidence": confidence,
                "session_id": session_id
            }
            
        except Exception as e:
            return {"error": str(e), "session_id": session_id}
    
    def generate_speech(self, text, voice_config=None):
        """Convert text to speech"""
        try:
            # Simulate text-to-speech (return dummy audio)
            # In production, integrate with Google TTS or Azure Speech
            return b"dummy_audio_content"
            
        except Exception as e:
            return None

voice_handler = VoiceChatHandler()

@app.route('/api/voice/session', methods=['POST'])
def create_voice_session():
    """Create new voice chat session"""
    data = request.get_json()
    user_id = data.get('user_id')
    agent_id = data.get('agent_id')
    
    session_id = voice_handler.create_session(user_id, agent_id)
    
    return jsonify({
        "session_id": session_id,
        "status": "created",
        "websocket_url": f"ws://localhost:7003"
    })

@app.route('/api/voice/process', methods=['POST'])
def process_voice():
    """Process voice input"""
    if 'audio' not in request.files:
        return jsonify({"error": "No audio file provided"}), 400
    
    audio_file = request.files['audio']
    session_id = request.form.get('session_id')
    
    audio_data = audio_file.read()
    result = voice_handler.process_audio(audio_data, session_id)
    
    return jsonify(result)

@app.route('/api/voice/synthesize', methods=['POST'])
def synthesize_speech():
    """Convert text to speech"""
    data = request.get_json()
    text = data.get('text')
    
    if not text:
        return jsonify({"error": "No text provided"}), 400
    
    audio_content = voice_handler.generate_speech(text)
    
    if audio_content:
        return Response(audio_content, mimetype='audio/mpeg')
    else:
        return jsonify({"error": "Speech synthesis failed"}), 500

# WebSocket handlers for real-time voice chat
@socketio.on('join_voice_chat')
def on_join(data):
    """Handle user joining voice chat"""
    session_id = data['session_id']
    join_room(session_id)
    
    emit('voice_chat_joined', {
        'session_id': session_id,
        'status': 'connected'
    }, room=session_id)

@socketio.on('voice_input')
def handle_voice_input(data):
    """Handle real-time voice input"""
    session_id = data['session_id']
    audio_chunk = data['audio_chunk']
    
    # Process audio chunk (simplified for demo)
    emit('voice_processed', {
        'session_id': session_id,
        'transcript': 'Processing audio...',
        'status': 'processing'
    }, room=session_id)

@socketio.on('leave_voice_chat')
def on_leave(data):
    """Handle user leaving voice chat"""
    session_id = data['session_id']
    leave_room(session_id)
    
    emit('voice_chat_left', {
        'session_id': session_id,
        'status': 'disconnected'
    }, room=session_id)

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "service": "voice-chat",
        "version": "1.0.0",
        "timestamp": datetime.utcnow().isoformat()
    })

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=7003, debug=True)