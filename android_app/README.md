You are a senior backend & mobile engineer with strong experience in:
- ASP.NET Core Web API (.NET 7+)
- Flutter
- Stream Chat (GetStream)
- Webhooks
- Database design for chat systems

PROJECT CONTEXT
----------------
I am building a chat system using Stream Chat for realtime messaging,
but I also need to store chat metadata in my own database for business logic,
permissions, reporting, and lifecycle management.

ARCHITECTURE (MUST FOLLOW)
--------------------------
Flutter
  │
  ▼
StreamChat (realtime messaging)
  │
  ▼
StreamChat Webhook
  │
  ▼
ASP.NET Core Web API
  │
  ▼
SQL Database (Conversation + Message Metadata)

GOALS
------
1. Use Stream Chat ONLY for realtime messaging
2. Store chat metadata in my own database
3. Backend controls all permissions and chat lifecycle
4. Frontend Flutter NEVER talks directly to database
5. Stream API Secret is NEVER exposed to Flutter

--------------------------------
BACKEND REQUIREMENTS (.NET)
--------------------------------
1. Use Stream Chat .NET SDK
2. Store Stream API Key and Secret in appsettings.json
3. Create StreamChatService that:
   - Creates / updates Stream users
   - Generates Stream Chat tokens
4. Implement REST APIs:
   - POST /api/chat/token
     → returns Stream userId + token
   - POST /api/chat/channel
     → creates or returns 1-1 channel
     → saves Conversation metadata in database
5. Implement Stream Chat Webhook endpoint:
   - POST /api/stream/webhook
   - Handle events:
     - channel.created
     - message.new
     - message.deleted
     - channel.deleted
6. Webhook must:
   - Validate Stream webhook signature
   - Store metadata only (NOT full message content)
7. Database schema MUST include:
   Conversation table:
     - Id (PK)
     - StreamChannelId
     - UserAId
     - UserBId
     - RelatedEntityId (PostId / AppointmentId)
     - IsActive
     - CreatedAt
     - LastMessageAt

   MessageMetadata table:
     - Id (PK)
     - StreamMessageId
     - ConversationId (FK)
     - SenderId
     - MessageType (text/image/audio)
     - CreatedAt
     - IsDeleted

--------------------------------
FRONTEND REQUIREMENTS (FLUTTER)
--------------------------------
1. Use stream_chat_flutter SDK
2. Connect user using token from backend
3. Create / join channels using backend API
4. Send messages via Stream Chat SDK:
   - Text
   - Image
   - Voice note (audio file upload, NOT realtime call)
5. Display chat UI using Stream widgets
6. Flutter must NOT manage metadata
7. Flutter must NOT access database directly

--------------------------------
VOICE NOTE RULES
--------------------------------
- Record audio in Flutter
- Send audio as message attachment
- Store audio file in Stream
- Store metadata only in DB via webhook
- MIME types: audio/mpeg, audio/wav

--------------------------------
SECURITY RULES (CRITICAL)
--------------------------------
- Stream API Secret only exists in backend
- Token generated only by backend
- Webhook signature verification is required
- Channel creation is validated against DB business rules

--------------------------------
OUTPUT FORMAT
--------------------------------
1. Brief architecture explanation
2. Database ERD (tables + relations)
3. ASP.NET Core code:
   - StreamChatService
   - ChatController
   - WebhookController
   - Webhook signature validation
   - EF Core models
4. Flutter code:
   - StreamChat initialization
   - Connect user
   - Channel join
   - Send text/image/audio
5. Best practices & production notes

--------------------------------
IMPORTANT
--------------------------------
- Do NOT store full message content in database
- Do NOT implement voice/video calling
- Do NOT use Firebase or other chat providers
- Use Stream Chat API only

Start implementing now.
