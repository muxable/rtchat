chat, err := s.liveChat(ctx, uid, token, r.ChannelID, r.VideoID)
	if err != nil {
		return nil, err
	}
	switch action {
	case "send":
		err = client.SendMessage(ctx, chat, r.Message)
	case "timeout":
		err = client.Ban(ctx, chat, r.UserID, r.Length)
	default:
		err = client.Ban(ctx, chat, r.UserID, 0)
	}
	var apiErr *youtube.APIError
	if r.VideoID == nil && errors.As(err, &apiErr) && chatGone(apiErr.Reason) {
		s.mu.Lock()
		delete(s.liveChats, chatCacheKey{uid, r.ChannelID})
		s.mu.Unlock()
	}
	return nil, youtubeError(err)
}
