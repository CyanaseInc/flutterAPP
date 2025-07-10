// Add these methods to your _MessageChatState class

Widget _buildAudioPlayer(BuildContext context) {
  // For sent messages (already have the file)
  if (widget.isMe) {
    return _buildLocalAudioPlayer();
  }

  // For received messages
  if (_mediaData == null) {
    return _buildAudioDownloadPlaceholder();
  }

  // If not downloaded yet
  if (_mediaData!['is_downloaded'] == 0) {
    return _showDownloadButton
        ? _buildAudioDownloadButton()
        : _isDownloading
            ? _buildAudioDownloadProgress()
            : _buildAudioDownloadPlaceholder();
  }

  // If downloaded
  return _buildDownloadedAudioPlayer();
}

Widget _buildLocalAudioPlayer() {
  final filePath = widget.message;
  if (filePath == null) {
    return _buildAudioErrorPlaceholder();
  }

  final file = File(filePath);
  if (!file.existsSync()) {
    return _buildAudioErrorPlaceholder();
  }

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    decoration: BoxDecoration(
      color: primaryColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            widget.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () {
            if (widget.onPlayAudio != null) {
              widget.onPlayAudio!(widget.messageId, filePath);
            }
          },
        ),
        const SizedBox(width: 8),
        Text(
          _formatDuration(widget.audioDuration),
          style: const TextStyle(color: Colors.white),
        ),
      ],
    ),
  );
}

Widget _buildDownloadedAudioPlayer() {
  final filePath = _mediaData?['file_path'];
  if (filePath == null) {
    return _buildAudioErrorPlaceholder();
  }

  final file = File(filePath);
  if (!file.existsSync()) {
    return _buildAudioErrorPlaceholder();
  }

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.yellow[100],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            widget.isPlaying ? Icons.pause : Icons.play_arrow,
            color: primaryColor,
            size: 28,
          ),
          onPressed: () {
            if (widget.onPlayAudio != null) {
              widget.onPlayAudio!(widget.messageId, filePath);
            }
          },
        ),
        const SizedBox(width: 8),
        Text(
          _formatDuration(widget.audioDuration),
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    ),
  );
}

Widget _buildAudioDownloadButton() {
  return GestureDetector(
    onTap: _downloadMedia,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.yellow[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.download,
            color: primaryColor,
            size: 28,
          ),
          const SizedBox(width: 8),
          Text(
            'Download Audio',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    ),
  );
}

Widget _buildAudioDownloadProgress() {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.yellow[100],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            value: _downloadProgress,
            backgroundColor: Colors.grey[400],
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(_downloadProgress * 100).toStringAsFixed(0)}%',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    ),
  );
}

Widget _buildAudioDownloadPlaceholder() {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.yellow[100],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.audio_file,
          color: Colors.grey[600],
          size: 28,
        ),
        const SizedBox(width: 8),
        Text(
          'Audio Message',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    ),
  );
}

Widget _buildAudioErrorPlaceholder() {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.yellow[100],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error,
          color: Colors.red,
          size: 28,
        ),
        const SizedBox(width: 8),
        Text(
          'Error loading audio',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    ),
  );
}