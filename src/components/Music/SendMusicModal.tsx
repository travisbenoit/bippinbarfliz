import React, { useState } from 'react';
import { X, Send, Loader2, Music, Heart } from 'lucide-react';
import { MusicSelector } from './MusicSelector';
import { musicService, Song } from '../../services/musicService';

interface SendMusicModalProps {
  isOpen: boolean;
  onClose: () => void;
  recipientId: string;
  recipientName: string;
  swarmId?: string;
  venueId?: string;
  onSendMusic?: (song: Song, message: string) => void;
}

export function SendMusicModal({
  isOpen,
  onClose,
  recipientId,
  recipientName,
  swarmId,
  venueId,
  onSendMusic
}: SendMusicModalProps) {
  const [selectedSong, setSelectedSong] = useState<Song | null>(null);
  const [message, setMessage] = useState('');
  const [isSending, setIsSending] = useState(false);
  const [sendSuccess, setSendSuccess] = useState(false);

  if (!isOpen) return null;

  const handleSend = async () => {
    if (!selectedSong) return;

    setIsSending(true);

    if (onSendMusic) {
      onSendMusic(selectedSong, message.trim());
      setIsSending(false);
      setSendSuccess(true);
      setTimeout(() => {
        handleClose();
      }, 1500);
    } else {
      const result = await musicService.sendMusicShare({
        recipientId,
        song: selectedSong,
        message: message.trim() || undefined,
        swarmId,
        venueId
      });

      setIsSending(false);

      if (result) {
        setSendSuccess(true);
        setTimeout(() => {
          handleClose();
        }, 2000);
      }
    }
  };

  const handleClose = () => {
    setSelectedSong(null);
    setMessage('');
    setSendSuccess(false);
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
      <div className="bg-white rounded-2xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-hidden flex flex-col">
        <div className="p-6 border-b border-gray-200 flex items-center justify-between bg-gradient-to-r from-blue-50 to-purple-50">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
              <Music className="w-5 h-5 text-white" />
            </div>
            <div>
              <h2 className="text-xl font-bold text-gray-900">Send a Song</h2>
              <p className="text-sm text-gray-600">to {recipientName}</p>
            </div>
          </div>
          <button
            onClick={handleClose}
            className="p-2 hover:bg-white/50 rounded-full transition-colors"
          >
            <X className="w-6 h-6 text-gray-600" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-6 space-y-6">
          {sendSuccess ? (
            <div className="flex flex-col items-center justify-center py-12">
              <div className="w-20 h-20 rounded-full bg-gradient-to-br from-green-400 to-blue-500 flex items-center justify-center mb-4 animate-bounce">
                <Heart className="w-10 h-10 text-white fill-white" />
              </div>
              <h3 className="text-2xl font-bold text-gray-900 mb-2">Song Sent!</h3>
              <p className="text-gray-600 text-center">
                {recipientName} will receive your music share
              </p>
            </div>
          ) : (
            <>
              <MusicSelector
                onSelectSong={setSelectedSong}
                selectedSong={selectedSong}
              />

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Add a message (optional)
                </label>
                <textarea
                  value={message}
                  onChange={(e) => setMessage(e.target.value)}
                  placeholder="Why are you sharing this song?"
                  rows={3}
                  maxLength={200}
                  className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
                />
                <p className="text-xs text-gray-500 mt-1 text-right">
                  {message.length}/200
                </p>
              </div>
            </>
          )}
        </div>

        {!sendSuccess && (
          <div className="p-6 border-t border-gray-200 bg-gray-50 flex gap-3">
            <button
              onClick={handleClose}
              className="flex-1 px-6 py-3 border border-gray-300 rounded-xl font-medium text-gray-700 hover:bg-gray-100 transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={handleSend}
              disabled={!selectedSong || isSending}
              className="flex-1 px-6 py-3 bg-gradient-to-r from-blue-500 to-purple-600 text-white rounded-xl font-medium hover:from-blue-600 hover:to-purple-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all flex items-center justify-center gap-2"
            >
              {isSending ? (
                <>
                  <Loader2 className="w-5 h-5 animate-spin" />
                  Sending...
                </>
              ) : (
                <>
                  <Send className="w-5 h-5" />
                  Send Song
                </>
              )}
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
