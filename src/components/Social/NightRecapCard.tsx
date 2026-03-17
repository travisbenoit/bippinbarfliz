import type { Ref } from 'react';
import { Moon, MapPin, Users, Wine, Music, Zap, Star } from 'lucide-react';
import type { NightRecapData } from '../../services/nightRecapService';

interface Props {
  recap: NightRecapData;
  userName: string;
  ref?: Ref<HTMLDivElement>;
}

function NightRecapCard({ recap, userName, ref }: Props) {
  return (
    <div
      ref={ref}
      className="relative overflow-hidden rounded-3xl"
      style={{
        background: 'linear-gradient(145deg, #0f0c29 0%, #1a1035 40%, #0f2027 100%)',
        width: '100%',
        minHeight: 480,
      }}
    >
      <div
        className="absolute inset-0 opacity-20"
        style={{
          backgroundImage:
            'radial-gradient(circle at 20% 20%, #E91E63 0%, transparent 50%), radial-gradient(circle at 80% 80%, #00bcd4 0%, transparent 50%)',
        }}
      />

      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        {[...Array(18)].map((_, i) => (
          <div
            key={i}
            className="absolute rounded-full opacity-30"
            style={{
              width: Math.random() * 3 + 1,
              height: Math.random() * 3 + 1,
              left: `${Math.random() * 100}%`,
              top: `${Math.random() * 100}%`,
              background: i % 3 === 0 ? '#E91E63' : i % 3 === 1 ? '#fff' : '#00bcd4',
            }}
          />
        ))}
      </div>

      <div className="relative z-10 p-6 flex flex-col gap-5">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-full bg-gradient-to-br from-[#E91E63] to-[#C2185B] flex items-center justify-center">
              <Moon className="w-4 h-4 text-white" />
            </div>
            <span className="text-white/60 text-xs font-medium tracking-widest uppercase">Night Recap</span>
          </div>
          <span className="text-white/40 text-xs">barfliz</span>
        </div>

        <div>
          <p className="text-white/50 text-xs uppercase tracking-widest mb-1">Last Night</p>
          <h2 className="text-white text-xl font-bold leading-tight">{recap.displayDate}</h2>
          {recap.startTime && (
            <p className="text-white/40 text-xs mt-1">
              {recap.startTime}{recap.endTime ? ` \u2014 ${recap.endTime}` : ''}
            </p>
          )}
        </div>

        <div className="grid grid-cols-2 gap-3">
          <StatTile
            icon={<MapPin className="w-4 h-4" />}
            value={recap.barsVisited.length}
            label={recap.barsVisited.length === 1 ? 'Bar visited' : 'Bars visited'}
            color="#E91E63"
          />
          <StatTile
            icon={<Users className="w-4 h-4" />}
            value={recap.peopleMet}
            label={recap.peopleMet === 1 ? 'Person met' : 'People met'}
            color="#00bcd4"
          />
          <StatTile
            icon={<Wine className="w-4 h-4" />}
            value={recap.drinksSent}
            label={recap.drinksSent === 1 ? 'Drink sent' : 'Drinks sent'}
            color="#ff9800"
          />
          {recap.swarmsJoined.length > 0 ? (
            <StatTile
              icon={<Star className="w-4 h-4" />}
              value={recap.swarmsJoined.length}
              label={recap.swarmsJoined.length === 1 ? 'Swarm joined' : 'Swarms joined'}
              color="#8bc34a"
            />
          ) : recap.xpEarned > 0 ? (
            <StatTile
              icon={<Zap className="w-4 h-4" />}
              value={recap.xpEarned}
              label="XP earned"
              color="#ffc107"
            />
          ) : (
            <StatTile
              icon={<Music className="w-4 h-4" />}
              value={recap.musicShared}
              label={recap.musicShared === 1 ? 'Song shared' : 'Songs shared'}
              color="#9c27b0"
            />
          )}
        </div>

        {recap.barsVisited.length > 0 && (
          <div className="bg-white/5 rounded-2xl p-4 border border-white/10">
            <p className="text-white/40 text-xs uppercase tracking-widest mb-2">Venues</p>
            <div className="flex flex-col gap-1.5">
              {recap.barsVisited.map((name, i) => (
                <div key={i} className="flex items-center gap-2">
                  <div
                    className="w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-bold text-white"
                    style={{ background: 'linear-gradient(135deg, #E91E63, #C2185B)' }}
                  >
                    {i + 1}
                  </div>
                  <span className="text-white/80 text-sm">{name}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        <div className="flex items-center justify-between pt-1">
          <div className="flex items-center gap-1.5">
            <div className="w-5 h-5 rounded-full bg-gradient-to-br from-[#E91E63] to-[#C2185B]" />
            <span className="text-white/60 text-xs">{userName}</span>
          </div>
          <span className="text-white/30 text-xs">barfliz.app</span>
        </div>
      </div>
    </div>
  );
}

function StatTile({
  icon,
  value,
  label,
  color,
}: {
  icon: React.ReactNode;
  value: number;
  label: string;
  color: string;
}) {
  return (
    <div className="bg-white/5 rounded-2xl p-4 border border-white/10 flex flex-col gap-1">
      <div className="flex items-center gap-1.5" style={{ color }}>
        {icon}
      </div>
      <p className="text-white text-3xl font-black leading-none mt-1">{value}</p>
      <p className="text-white/50 text-xs">{label}</p>
    </div>
  );
}

export default NightRecapCard;
