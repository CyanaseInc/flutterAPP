from django.db import models
from django.contrib.auth.models import User

class Group(models.Model):
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_groups')
    avatar = models.URLField(blank=True, null=True)
    updated_at = models.DateTimeField(auto_now=True)
    subscription_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    deposit_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    restrict_messages_to_admins = models.BooleanField(default=False)
    allows_subscription = models.BooleanField(default=False)

    def __str__(self):
        return self.name

class ChatRoom(models.Model):
    name = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_group = models.BooleanField(default=False)
    associated_group_id = models.ForeignKey(
        Group,
        on_delete=models.CASCADE,
        related_name='chat_rooms',
        null=True,
        blank=True
    )

    def __str__(self):
        return self.name

class Participant(models.Model):
    group = models.ForeignKey(Group, on_delete=models.CASCADE, related_name='participants')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='group_participations')
    is_admin = models.BooleanField(default=False)
    is_approved = models.BooleanField(default=True)
    is_denied = models.BooleanField(default=False)
    joined_at = models.DateTimeField(auto_now_add=True)
    muted = models.BooleanField(default=False)
    role = models.CharField(max_length=50, default='member')

    class Meta:
        unique_together = ('group', 'user')

    def __str__(self):
        return f"{self.user.username} in {self.group.name}"

class Message(models.Model):
    chat_room = models.ForeignKey(ChatRoom, on_delete=models.CASCADE, related_name='messages')
    sender = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sent_messages')
    content = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)
    type = models.CharField(max_length=20, default='text')  # text, image, audio
    is_read = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.sender.username}: {self.content[:50]}" 