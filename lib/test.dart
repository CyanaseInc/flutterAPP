class _MessageChatState extends State<MessageChat> with SingleTickerProviderStateMixin {
  // ... existing fields
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  Map<String, dynamic>? _mediaData;

  @override
  void initState() {
    super.initState();
    // ... existing initState
    _loadMediaData();
  }

  Future<void> _loadMediaData() async {
    if (widget.isImage || widget.isAudio) {
      final media = await DatabaseHelper().getMedia(int.parse(widget.messageId));
      if (mounted) {
        setState(() {
          _mediaData = media;
        });
      }
    }
  }

  Future<void> _downloadMedia() async {
    if (_mediaData == null || _mediaData!['url'] == null) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    final mediaInfo = await MediaDownloader.downloadMedia(
      url: _mediaData!['url'],
      type: widget.isImage ? 'image' : 'audio',
      messageId: int.parse(widget.messageId),
    );

    if (mediaInfo != null && mounted) {
      await DatabaseHelper().updateMedia(
        messageId: int.parse(widget.messageId),
        filePath: mediaInfo['file_path'],
        isDownloaded: true,
        fileSize: mediaInfo['file_size'],
        duration: mediaInfo['duration'],
      );
      setState(() {
        _mediaData = {
          ..._mediaData!,
          'file_path': mediaInfo['file_path'],
          'is_downloaded': 1,
          'file_size': mediaInfo['file_size'],
          'duration': mediaInfo['duration'],
        };
        _isDownloading = false;
      });
    } else if (mounted) {
      setState(() {
        _isDownloading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download failed')),
      );
    }
  }

  Widget _buildImageViewer(BuildContext context) {
    if (_mediaData == null || _mediaData!['is_downloaded'] == 0) {
      return GestureDetector(
        onTap: _isDownloading ? null : _downloadMedia,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Blurred placeholder
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _mediaData != null && _mediaData!['blurhash'] != null
                    ? BlurHash(
                        hash: _mediaData!['blurhash'],
                        imageFit: BoxFit.cover,
                      )
                    : widget.message != null
                        ? Image.file(
                            File(widget.message!),
                            fit: BoxFit.cover,
                            color: Colors.black.withOpacity(0.5),
                            colorBlendMode: BlendMode.darken,
                            errorBuilder: (context, error, stackTrace) => Container(),
                          )
                        : Container(),
              ),
            ),
            // Download button or progress
            _isDownloading
                ? CircularProgressIndicator(
                    value: _downloadProgress,
                    color: Colors.white,
                  )
                : Semantics(
                    button: true,
                    label: 'Download image',
                    child: Icon(
                      Icons.download,
                      size: 40,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImage(imagePath: _mediaData!['file_path']),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(_mediaData!['file_path']),
          width: 180,
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.image_not_supported,
                size: 40,
                color: widget.isMe ? primaryColor : Colors.grey[600],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAudioPlayer(BuildContext context) {
    if (_mediaData == null || _mediaData!['is_downloaded'] == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: widget.isMe ? primaryColor : Colors.yellow[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Semantics(
                button: true,
                label: 'Download audio',
                child: Icon(
                  Icons.download,
                  color: widget.isMe ? white : primaryColor,
                  size: 24,
                ),
              ),
              onPressed: _isDownloading ? null : _downloadMedia,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            _isDownloading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Download',
                    style: TextStyle(
                      color: widget.isMe ? white : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
            const SizedBox(width: 8),
            Icon(
              Icons.mic,
              size: 20,
              color: widget.isMe ? white : Colors.grey[600],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: widget.isMe ? primaryColor : Colors.yellow[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              widget.isPlaying ? Icons.pause_circle : Icons.play_circle,
              color: widget.isMe ? white : primaryColor,
              size: 28,
            ),
            onPressed: () {
              if (_mediaData!['file_path'] != null && widget.onPlayAudio != null) {
                widget.onPlayAudio!(widget.messageId, _mediaData!['file_path']);
              }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),
                LinearProgressIndicator(
                  value: _mediaData!['duration'] != null && _mediaData!['duration'] > 0
                      ? widget.audioPosition.inSeconds / _mediaData!['duration']
                      : 0.0,
                  backgroundColor: white,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.isPlaying ? primaryTwo : Colors.grey[600]!,
                  ),
                  minHeight: 3,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.isPlaying
                          ? _formatDuration(widget.audioPosition)
                          : _formatDuration(Duration(seconds: _mediaData!['duration'] ?? 0)),
                      style: TextStyle(
                        color: widget.isMe ? white : Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                    Icon(
                      Icons.mic,
                      size: 20,
                      color: widget.isMe ? white : Colors.grey[600],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // ... rest of MessageChatState
}