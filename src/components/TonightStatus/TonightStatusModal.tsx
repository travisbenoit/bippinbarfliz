import { useState, useEffect } from 'react';
import { X, MapPin, ChevronRight } from 'lucide-react';
import { supabase } from '../../lib/supabase';

type TonightStatus = 'going_out' | 'maybe' | 'staying_in' | null;

interface TonightStatusModalProps {
  isOpen: boolean;
  onClose: () => void;
  currentStatus: TonightStatus;
  currentVenue: string | null;
  onSave: (status: TonightStatus, venue: string | null) => void;
}

const STATUS_OPTIONS = [
  {
    value: 'going_out' as const,
    label: 'Going Out',
    description: 'Ready to hit the town tonight',
    color: 'bg-emerald-500',
    glow: 'shadow-[0_0_20px_rgba(16,185,129,0.4)]',
    selectedBg: 'bg-emerald-500/20',
    selectedBorder: 'border-emerald-500/50',
  },
  {
    value: 'maybe' as const,
    label: 'Maybe',
    description: 'Depends on the plans',
    color: 'bg-amber-500',
    glow: 'shadow-[0_0_20px_rgba(245,158,11,0.4)]',
    selectedBg: 'bg-amber-500/20',
    selectedBorder: 'border-amber-500/50',
  },
  {
    value: 'staying_in' as const,
    label: 'Staying In',
    description: 'Not tonight',
    color: 'bg-gray-500',
    glow: '',
    selectedBg: 'bg-white/5',
    selectedBorder: 'border-white/20',
  },
];

export default function TonightStatusModal({
  isOpen,
  onClose,
  currentStatus,
  currentVenue,
  onSave,
}: TonightStatusModalProps) {
  const [selectedStatus, setSelectedStatus] = useState<TonightStatus>(currentStatus);
  const [selectedVenue, setSelectedVenue] = useState<string | null>(currentVenue);
  const [showVenueSelect, setShowVenueSelect] = useState(false);
  const [venues, setVenues] = useState<Array<{ id: string; name: string; address: string }>>([]);

  useEffect(() => {
    if (!isOpen) return;
    supabase
      .from('venues')
      .select('id, name, address')
      .eq('is_active', true)
      .order('name')
      .limit(20)
      .then(({ data }) => { if (data) setVenues(data); });
  }, [isOpen]);

  const handleSave = () => {
    onSave(selectedStatus, selectedStatus === 'going_out' ? selectedVenue : null);
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[2000] flex items-end sm:items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/70 backdrop-blur-md" onClick={onClose} />
      <div className="relative bg-midnight-900 rounded-3xl w-full max-w-md max-h-[90vh] overflow-hidden animate-slide-up border border-white/10">
        <div className="p-6 border-b border-white/10">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-xl font-bold text-white">Tonight's Status</h2>
              <p className="text-sm text-white/50 mt-1">Let friends know your plans</p>
            </div>
            <button
              onClick={onClose}
              className="p-2 hover:bg-white/10 rounded-full transition-colors"
            >
              <X className="w-5 h-5 text-white/50" />
            </button>
          </div>
        </div>

        <div className="p-6 space-y-3 overflow-y-auto max-h-[60vh]">
          {STATUS_OPTIONS.map((option) => (
            <button
              key={option.value}
              onClick={() => {
                setSelectedStatus(option.value);
                if (option.value !== 'going_out') {
                  setSelectedVenue(null);
                  setShowVenueSelect(false);
                }
              }}
              className={`w-full p-4 rounded-2xl border-2 transition-all text-left ${
                selectedStatus === option.value
                  ? `${option.selectedBg} ${option.selectedBorder}`
                  : 'border-white/10 hover:border-white/20 bg-white/5'
              }`}
            >
              <div className="flex items-center gap-4">
                <div className={`w-5 h-5 rounded-full ${option.color} ${selectedStatus === option.value ? option.glow : ''} transition-all`} />
                <div className="flex-1">
                  <p className="font-semibold text-white">{option.label}</p>
                  <p className="text-sm text-white/50">{option.description}</p>
                </div>
              </div>
            </button>
          ))}

          {selectedStatus === 'going_out' && (
            <div className="pt-4 border-t border-white/10 mt-6">
              <div className="flex items-center gap-2 mb-4">
                <MapPin className="w-5 h-5 text-coral-400" />
                <span className="font-semibold text-white">Where to?</span>
                <span className="text-sm text-white/40">(optional)</span>
              </div>

              {selectedVenue ? (
                <div className="flex items-center justify-between p-4 bg-coral-500/20 rounded-xl border border-coral-500/30">
                  <span className="font-medium text-coral-300">{selectedVenue}</span>
                  <button
                    onClick={() => setSelectedVenue(null)}
                    className="text-sm text-coral-400 hover:text-coral-300"
                  >
                    Change
                  </button>
                </div>
              ) : (
                <button
                  onClick={() => setShowVenueSelect(!showVenueSelect)}
                  className="w-full p-4 border-2 border-dashed border-white/20 rounded-xl text-white/50 hover:border-coral-500/50 hover:text-coral-400 transition-colors flex items-center justify-between"
                >
                  <span>Select a venue</span>
                  <ChevronRight className={`w-5 h-5 transition-transform ${showVenueSelect ? 'rotate-90' : ''}`} />
                </button>
              )}

              {showVenueSelect && !selectedVenue && (
                <div className="mt-3 max-h-48 overflow-y-auto space-y-2 scrollbar-hide">
                  {venues.map((venue) => (
                    <button
                      key={venue.id}
                      onClick={() => {
                        setSelectedVenue(venue.name);
                        setShowVenueSelect(false);
                      }}
                      className="w-full p-3 bg-white/5 rounded-xl text-left hover:bg-white/10 transition-colors"
                    >
                      <p className="font-medium text-white">{venue.name}</p>
                      <p className="text-xs text-white/40">{venue.address.split(',')[0]}</p>
                    </button>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>

        <div className="p-6 border-t border-white/10 bg-midnight-950/50">
          <button
            onClick={handleSave}
            className="w-full btn-primary py-4"
          >
            Update Status
          </button>
        </div>
      </div>
    </div>
  );
}
