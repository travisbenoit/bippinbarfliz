import { useState, useEffect } from 'react';
import { Sun, Moon } from 'lucide-react';

interface TimePickerProps {
  value: string;
  onChange: (time24: string) => void;
}

export default function TimePicker({ value, onChange }: TimePickerProps) {
  const [hour, setHour] = useState(9);
  const [minute, setMinute] = useState(0);
  const [period, setPeriod] = useState<'AM' | 'PM'>('PM');

  useEffect(() => {
    if (value) {
      const [h, m] = value.split(':').map(Number);
      const isPM = h >= 12;
      const hour12 = h % 12 || 12;
      setHour(hour12);
      setMinute(m);
      setPeriod(isPM ? 'PM' : 'AM');
    }
  }, []);

  const updateTime = (newHour: number, newMinute: number, newPeriod: 'AM' | 'PM') => {
    let hour24 = newHour;
    if (newPeriod === 'PM' && newHour !== 12) {
      hour24 = newHour + 12;
    } else if (newPeriod === 'AM' && newHour === 12) {
      hour24 = 0;
    }
    const time24 = `${hour24.toString().padStart(2, '0')}:${newMinute.toString().padStart(2, '0')}`;
    onChange(time24);
  };

  const handleHourChange = (newHour: number) => {
    setHour(newHour);
    updateTime(newHour, minute, period);
  };

  const handleMinuteChange = (newMinute: number) => {
    setMinute(newMinute);
    updateTime(hour, newMinute, period);
  };

  const handlePeriodChange = (newPeriod: 'AM' | 'PM') => {
    setPeriod(newPeriod);
    updateTime(hour, minute, newPeriod);
  };

  const hours = [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
  const minutes = [0, 15, 30, 45];

  return (
    <div className="bg-white rounded-xl border-2 border-gray-200 p-4 space-y-4">
      <div className="flex items-center justify-between rounded-xl overflow-hidden border-2 border-gray-200">
        <button
          type="button"
          onClick={() => handlePeriodChange('AM')}
          className={`flex-1 flex items-center justify-center gap-2 py-4 font-bold text-lg transition-all ${
            period === 'AM'
              ? 'bg-amber-400 text-white shadow-inner'
              : 'bg-gray-50 text-gray-400 hover:bg-gray-100'
          }`}
        >
          <Sun className={`w-5 h-5 ${period === 'AM' ? 'text-white' : 'text-gray-400'}`} />
          AM
        </button>
        <div className="w-px h-12 bg-gray-200" />
        <button
          type="button"
          onClick={() => handlePeriodChange('PM')}
          className={`flex-1 flex items-center justify-center gap-2 py-4 font-bold text-lg transition-all ${
            period === 'PM'
              ? 'bg-[#1e3a5f] text-white shadow-inner'
              : 'bg-gray-50 text-gray-400 hover:bg-gray-100'
          }`}
        >
          <Moon className={`w-5 h-5 ${period === 'PM' ? 'text-white' : 'text-gray-400'}`} />
          PM
        </button>
      </div>

      <div>
        <p className="text-xs font-medium text-gray-500 mb-2">Hour</p>
        <div className="grid grid-cols-6 gap-2">
          {hours.map((h) => (
            <button
              key={h}
              type="button"
              onClick={() => handleHourChange(h)}
              className={`py-2.5 rounded-lg font-semibold text-sm transition-colors ${
                hour === h
                  ? 'bg-[#E91E63] text-white shadow-md'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              {h}
            </button>
          ))}
        </div>
      </div>

      <div>
        <p className="text-xs font-medium text-gray-500 mb-2">Minute</p>
        <div className="grid grid-cols-4 gap-2">
          {minutes.map((m) => (
            <button
              key={m}
              type="button"
              onClick={() => handleMinuteChange(m)}
              className={`py-2.5 rounded-lg font-semibold text-sm transition-colors ${
                minute === m
                  ? 'bg-[#E91E63] text-white shadow-md'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              :{m.toString().padStart(2, '0')}
            </button>
          ))}
        </div>
      </div>

      <div className={`pt-3 border-t border-gray-100 rounded-lg px-4 py-3 ${
        period === 'AM' ? 'bg-amber-50' : 'bg-slate-50'
      }`}>
        <p className={`text-center text-xl font-bold ${
          period === 'AM' ? 'text-amber-700' : 'text-slate-700'
        }`}>
          {hour}:{minute.toString().padStart(2, '0')} {period}
        </p>
        <p className="text-center text-xs text-gray-400 mt-1">
          {period === 'AM' ? 'Morning' : hour === 12 ? 'Noon' : hour <= 5 ? 'Late Night' : 'Evening'}
        </p>
      </div>
    </div>
  );
}
