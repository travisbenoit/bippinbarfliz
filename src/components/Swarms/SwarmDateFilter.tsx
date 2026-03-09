import { Calendar, ChevronDown } from 'lucide-react';
import { useState } from 'react';

export type DateFilterOption = 'today' | 'tomorrow' | 'week' | 'weekend' | 'all';

interface SwarmDateFilterProps {
  selectedFilter: DateFilterOption;
  onFilterChange: (filter: DateFilterOption) => void;
}

export default function SwarmDateFilter({
  selectedFilter,
  onFilterChange,
}: SwarmDateFilterProps) {
  const [isOpen, setIsOpen] = useState(false);

  const filters: { value: DateFilterOption; label: string; icon?: string }[] = [
    { value: 'today', label: 'Today' },
    { value: 'tomorrow', label: 'Tomorrow' },
    { value: 'week', label: 'This Week' },
    { value: 'weekend', label: 'This Weekend' },
    { value: 'all', label: 'All Swarms' },
  ];

  const selectedLabel = filters.find(f => f.value === selectedFilter)?.label || 'Filter by Date';

  const getFilterLabel = () => {
    switch (selectedFilter) {
      case 'today':
        return 'Today';
      case 'tomorrow':
        return 'Tomorrow';
      case 'week':
        return 'This Week';
      case 'weekend':
        return 'This Weekend';
      case 'all':
        return 'All Swarms';
      default:
        return 'Filter by Date';
    }
  };

  return (
    <div className="relative">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 px-4 py-2 bg-white border border-gray-200 rounded-full font-medium text-sm text-gray-700 hover:bg-gray-50 transition-colors"
      >
        <Calendar size={16} />
        <span>{getFilterLabel()}</span>
        <ChevronDown
          size={16}
          className={`transition-transform ${isOpen ? 'rotate-180' : ''}`}
        />
      </button>

      {isOpen && (
        <div className="absolute top-full mt-2 right-0 bg-white border border-gray-200 rounded-xl shadow-lg z-10">
          {filters.map((filter) => (
            <button
              key={filter.value}
              onClick={() => {
                onFilterChange(filter.value);
                setIsOpen(false);
              }}
              className={`w-full text-left px-4 py-3 font-medium transition-colors whitespace-nowrap ${
                selectedFilter === filter.value
                  ? 'bg-[#E91E63] text-white'
                  : 'text-gray-700 hover:bg-gray-50'
              } ${filter === filters[0] ? 'rounded-t-lg' : ''} ${
                filter === filters[filters.length - 1] ? 'rounded-b-lg' : ''
              }`}
            >
              {filter.label}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

export function getSwarmFilterRange(filter: DateFilterOption): { start: Date; end: Date } {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  const getWeekStart = (date: Date) => {
    const d = new Date(date);
    const day = d.getDay();
    const diff = d.getDate() - day + (day === 0 ? -6 : 1);
    return new Date(d.setDate(diff));
  };

  const getWeekEnd = (date: Date) => {
    const d = new Date(date);
    const day = d.getDay();
    const diff = d.getDate() - day + (day === 0 ? 0 : 7);
    return new Date(d.setDate(diff));
  };

  const weekStart = new Date(getWeekStart(today));
  weekStart.setHours(0, 0, 0, 0);

  const weekEnd = new Date(getWeekEnd(today));
  weekEnd.setHours(23, 59, 59, 999);

  const getSaturdayOfWeek = (date: Date) => {
    const d = new Date(date);
    const day = d.getDay();
    const diff = d.getDate() - day + 6;
    return new Date(d.setDate(diff));
  };

  const sundayOfWeek = new Date(getSaturdayOfWeek(today));
  sundayOfWeek.setDate(sundayOfWeek.getDate() + 1);
  sundayOfWeek.setHours(23, 59, 59, 999);

  const saturdayStart = new Date(getSaturdayOfWeek(today));
  saturdayStart.setHours(0, 0, 0, 0);

  switch (filter) {
    case 'today':
      return {
        start: today,
        end: new Date(today.getTime() + 24 * 60 * 60 * 1000 - 1),
      };
    case 'tomorrow':
      return {
        start: tomorrow,
        end: new Date(tomorrow.getTime() + 24 * 60 * 60 * 1000 - 1),
      };
    case 'week':
      return {
        start: weekStart,
        end: weekEnd,
      };
    case 'weekend':
      return {
        start: saturdayStart,
        end: sundayOfWeek,
      };
    case 'all':
    default:
      return {
        start: new Date(1970, 0, 1),
        end: new Date(2099, 11, 31),
      };
  }
}

export function filterSwarmsByDate(
  swarms: any[],
  dateFilter: DateFilterOption
): any[] {
  if (dateFilter === 'all') return swarms;

  const { start, end } = getSwarmFilterRange(dateFilter);

  return swarms.filter((swarm) => {
    if (!swarm.start_time) return true;
    const swarmTime = new Date(swarm.start_time);
    return swarmTime >= start && swarmTime <= end;
  });
}
