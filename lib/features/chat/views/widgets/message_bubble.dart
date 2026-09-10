import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String messageId;
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final String? imageUrl;
  final String status; // 'sending', 'sent', 'delivered', 'read', 'failed'

  const MessageBubble({
    super.key,
    required this.messageId,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.imageUrl,
    this.status = 'sent',
  });

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  IconData _getStatusIcon() {
    switch (status) {
      case 'sending':
        return Icons.access_time;
      case 'sent':
        return Icons.check;
      case 'delivered':
        return Icons.done_all;
      case 'read':
        return Icons.done_all;
      case 'failed':
        return Icons.error_outline;
      default:
        return Icons.check;
    }
  }

  Color _getStatusColor() {
    switch (status) {
      case 'sending':
        return Colors.grey;
      case 'sent':
        return Colors.white70;
      case 'delivered':
        return Colors.white70;
      case 'read':
        return Colors.lightBlueAccent;
      case 'failed':
        return Colors.red;
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // Burbuja de mensaje
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isMe ? Colors.green.shade600 : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen si existe
                    if (imageUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl!,
                          width: 200,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 200,
                              height: 200,
                              color: Colors.grey.shade200,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Texto del mensaje
                    if (text.isNotEmpty)
                      Text(
                        text,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Timestamp y estado
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(timestamp),
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            _getStatusIcon(),
                            size: 14,
                            color: _getStatusColor(),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
