# SSE to Poe Protocol Adapter API

## Overview

The SSE to Poe Protocol Adapter API acts as a bridge between Server-Sent Events (SSE) and the Poe Protocol. It facilitates the conversion of SSE streams into the format expected by the Poe Protocol, enabling seamless integration between systems that utilize these different communication protocols.

## API Information

- **Version**: 1.0.0
- **Contact**: [API Support](https://example.com/support) (support@example.com)
- **License**: [Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0.html)

## Servers

- **Example production placeholder server**: `https://api.example.com/v1`
- **Example development placeholder server**: `https://api-dev.example.com/v1`

## Endpoints

### 1. Convert SSE Stream to Poe Protocol Format

- **Endpoint**: `/stream-to-poe`
- **Method**: `POST`
- **Operation ID**: `convertSseToPoe`
- **Description**: Converts an SSE stream URL into the Poe Protocol format.
- **Request Body**:
  - `sseUrl` (string, required): URL of the SSE stream to convert.
  - `contentType` (string, optional): Content type for the Poe Protocol meta event (default: `text/markdown`).
  - `suggestedReplies` (boolean, optional): Whether to suggest replies to the user (default: `false`).
  - `headers` (object, optional): Additional headers for the SSE request.

- **Responses**:
  - `200`: SSE stream converted to Poe Protocol format.
  - `400`: Invalid request.
  - `401`: Unauthorized.
  - `404`: SSE stream not found.
  - `500`: Server error.

### 2. Convert Poe Protocol Messages to SSE Streams

- **Endpoint**: `/poe-to-stream`
- **Method**: `POST`
- **Operation ID**: `convertPoeToSse`
- **Description**: Converts Poe Protocol messages into SSE streams.
- **Request Body**:
  - `content` (string, required): Content to convert to an SSE stream.
  - `eventType` (string, optional): The SSE event type to use (default: `message`).
  - `eventId` (string, optional): Optional event ID for the SSE stream.
  - `retryInterval` (integer, optional): Optional retry interval in milliseconds.

- **Responses**:
  - `200`: Poe Protocol message converted to SSE stream.
  - `400`: Invalid request.
  - `401`: Unauthorized.
  - `500`: Server error.

### 3. Handle Poe Query Requests

- **Endpoint**: `/poe/query`
- **Method**: `POST`
- **Operation ID**: `handlePoeQuery`
- **Description**: Processes Poe query requests according to the Poe Protocol.
- **Request Body**: 
  - `version`, `type`, `query`, `message_id`, `user_id`, `conversation_id` (all required).

- **Responses**:
  - `200`: Successful response to query.
  - `400`: Invalid request.
  - `401`: Unauthorized.
  - `500`: Server error.

### 4. Handle Poe Settings Requests

- **Endpoint**: `/poe/settings`
- **Method**: `POST`
- **Operation ID**: `handlePoeSettings`
- **Description**: Returns bot settings according to the Poe Protocol.
- **Request Body**: 
  - `version`, `type` (both required).

- **Responses**:
  - `200`: Bot settings.
  - `400`: Invalid request.
  - `401`: Unauthorized.
  - `500`: Server error.

### 5. Handle Poe Reaction Reports

- **Endpoint**: `/poe/report-reaction`
- **Method**: `POST`
- **Operation ID**: `handlePoeReactionReport`
- **Description**: Accepts reports of user reactions to bot messages.
- **Request Body**: 
  - `version`, `type`, `message_id`, `user_id`, `conversation_id`, `reaction` (all required).

- **Responses**:
  - `200`: Reaction received.
  - `400`: Invalid request.
  - `401`: Unauthorized.
  - `500`: Server error.

### 6. Handle Poe Error Reports

- **Endpoint**: `/poe/report-error`
- **Method**: `POST`
- **Operation ID**: `handlePoeErrorReport`
- **Description**: Accepts error reports from Poe.
- **Request Body**: 
  - `version`, `type`, `message` (all required).

- **Responses**:
  - `200`: Error report received.
  - `400`: Invalid request.
  - `401`: Unauthorized.
  - `500`: Server error.

## Security

The API uses two types of authentication:

- **`ApiKeyAuth`**: Requires an API key in the header (`X-API-Key`).
- **`BearerAuth`**: Requires HTTP `bearer` authentication for Poe Protocol
  endpoints.

## Error Handling

All endpoints return standardized error responses with the following structure:

```json
{
  "error": "error_code",
  "message": "error_message",
  "details": {
    "parameter": "parameter_name",
    "reason": "reason_for_error"
  }
}
```

## Conclusion

This API provides a robust solution for integrating SSE streams with the Poe Protocol, enabling developers to build applications that leverage both technologies effectively. For further assistance, please contact our support team.
