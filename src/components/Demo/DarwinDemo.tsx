import { useState } from 'react';
import { X, MapPin as MapPinIcon, Star, Users, MessageCircle, Navigation, ZoomIn, ZoomOut } from 'lucide-react';

interface DarwinBar {
  id: string;
  name: string;
  lat: number;
  lng: number;
  rating: number;
  reviewCount: number;
  address: string;
  category: string;
  photos: string[];
  openNow: boolean;
  distance: number;
}

const DARWIN_BARS: DarwinBar[] = [
  {
    id: 'bar1',
    name: 'Mitchell Street Bar',
    lat: -12.4620,
    lng: 130.8320,
    rating: 4.6,
    reviewCount: 328,
    address: '10 Mitchell St, Darwin NT 0800',
    category: 'bar',
    photos: ['https://images.pexels.com/photos/2624436/pexels-photo-2624436.jpeg?auto=compress&cs=tinysrgb&w=400'],
    openNow: true,
    distance: 0.8,
  },
  {
    id: 'bar2',
    name: 'Sky Bar Darwin',
    lat: -12.4550,
    lng: 130.8350,
    rating: 4.5,
    reviewCount: 412,
    address: '33 Marina Blvd, Darwin NT 0800',
    category: 'rooftop',
    photos: ['https://images.pexels.com/photos/3962286/pexels-photo-3962286.jpeg?auto=compress&cs=tinysrgb&w=400'],
    openNow: true,
    distance: 1.1,
  },
  {
    id: 'bar3',
    name: 'The Deck Bar',
    lat: -12.4650,
    lng: 130.8280,
    rating: 4.3,
    reviewCount: 276,
    address: '8 Knuckey St, Darwin NT 0800',
    category: 'bar',
    photos: ['https://images.pexels.com/photos/3407857/pexels-photo-3407857.jpeg?auto=compress&cs=tinysrgb&w=400'],
    openNow: true,
    distance: 0.5,
  },
  {
    id: 'bar4',
    name: 'Monsoons Wine Bar',
    lat: -12.4700,
    lng: 130.8400,
    rating: 4.7,
    reviewCount: 198,
    address: '64 Smith St, Darwin NT 0800',
    category: 'lounge',
    photos: ['https://images.pexels.com/photos/2608517/pexels-photo-2608517.jpeg?auto=compress&cs=tinysrgb&w=400'],
    openNow: false,
    distance: 1.4,
  },
  {
    id: 'bar5',
    name: 'Shenanigans Irish Bar',
    lat: -12.4580,
    lng: 130.8290,
    rating: 4.4,
    reviewCount: 534,
    address: '69 Mitchell St, Darwin NT 0800',
    category: 'bar',
    photos: ['https://images.pexels.com/photos/1283219/pexels-photo-1283219.jpeg?auto=compress&cs=tinysrgb&w=400'],
    openNow: true,
    distance: 0.6,
  },
];

export default function DarwinDemo() {
  const [zoom, setZoom] = useState(14);
  const [selectedBar, setSelectedBar] = useState<DarwinBar | null>(DARWIN_BARS[0]);
  const [activeTab, setActiveTab] = useState<'map' | 'list'>('list');

  const mapCenter = { lat: -12.4620, lng: 130.8320 };

  const latLngToPixel = (lat: number, lng: number) => {
    const scale = Math.pow(2, zoom);
    const worldWidth = 256 * scale;
    const worldHeight = 256 * scale;
    const centerX = (mapCenter.lng + 180) * (worldWidth / 360);
    const centerY = (worldHeight / 2) - (worldHeight * Math.log(Math.tan((Math.PI / 4) + (mapCenter.lat * Math.PI / 360))) / (2 * Math.PI));
    const x = (lng + 180) * (worldWidth / 360);
    const y = (worldHeight / 2) - (worldHeight * Math.log(Math.tan((Math.PI / 4) + (lat * Math.PI / 360))) / (2 * Math.PI));
    return {
      x: (x - centerX) + (window.innerWidth / 2),
      y: (y - centerY) + (window.innerHeight * 0.4),
    };
  };

  const getCategoryIcon = (category: string) => {
    const icons: Record<string, string> = {
      club: '🎵',
      brewery: '🍺',
      rooftop: '🌆',
      lounge: '🍸',
      sports_bar: '🏈',
      bar: '🍻',
    };
    return icons[category] || '🍻';
  };

  return (
    <div className="h-screen flex flex-col bg-white overflow-hidden">
      <div className="flex items-center justify-between p-6 border-b border-gray-100 bg-gradient-to-br from-blue-50 to-teal-50">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Darwin Bar Finder Demo</h1>
          <p className="text-gray-600 mt-1">See what the app looks like with real bar data</p>
        </div>
        <div className="text-4xl">🌏</div>
      </div>

      <div className="flex-1 flex overflow-hidden">
        {/* Map View */}
        <div className={`relative flex-1 bg-gradient-to-br from-emerald-100 via-teal-50 to-cyan-100 transition-all ${activeTab === 'list' && 'hidden lg:flex'}`}>
          <div
            className="absolute inset-0 opacity-40"
            style={{
              backgroundImage: `
                repeating-linear-gradient(0deg, transparent, transparent 80px, rgba(0,100,80,0.08) 80px, rgba(0,100,80,0.08) 81px),
                repeating-linear-gradient(90deg, transparent, transparent 80px, rgba(0,100,80,0.08) 80px, rgba(0,100,80,0.08) 81px)
              `,
            }}
          />

          <svg className="absolute inset-0 w-full h-full opacity-20" style={{ pointerEvents: 'none' }}>
            <defs>
              <pattern id="roads" patternUnits="userSpaceOnUse" width="200" height="200">
                <path d="M0 100 L200 100" stroke="#64748b" strokeWidth="2" fill="none" />
                <path d="M100 0 L100 200" stroke="#64748b" strokeWidth="2" fill="none" />
              </pattern>
            </defs>
            <rect width="100%" height="100%" fill="url(#roads)" />
          </svg>

          {DARWIN_BARS.map((bar) => {
            const pos = latLngToPixel(bar.lat, bar.lng);
            const isSelected = selectedBar?.id === bar.id;
            return (
              <div
                key={bar.id}
                className="absolute transform -translate-x-1/2 -translate-y-1/2 cursor-pointer transition-all duration-200 z-10"
                style={{ left: pos.x, top: pos.y }}
                onClick={() => setSelectedBar(bar)}
              >
                <div className={`relative group transition-all ${isSelected ? 'scale-125' : 'scale-100 hover:scale-110'}`}>
                  <div className={`absolute inset-0 ${isSelected ? 'bg-emerald-500/40' : 'bg-[#E91E63]/20'} rounded-2xl blur-xl transition-all`} />
                  <div className={`relative w-14 h-14 rounded-2xl ${isSelected ? 'bg-gradient-to-br from-emerald-500 to-teal-600' : 'bg-white border border-gray-200'} shadow-lg flex items-center justify-center text-2xl`}>
                    {getCategoryIcon(bar.category)}
                  </div>
                  <div className={`absolute -bottom-2 -right-2 px-2 py-1 rounded-full text-xs font-bold shadow-lg border ${isSelected ? 'bg-emerald-500 text-white' : 'bg-white text-gray-900 border-gray-100'}`}>
                    {bar.rating}
                  </div>
                </div>
              </div>
            );
          })}

          <div className="absolute top-6 right-6 z-20 flex flex-col gap-2">
            <button
              onClick={() => setZoom(Math.min(zoom + 1, 18))}
              className="w-11 h-11 bg-white shadow-lg rounded-2xl flex items-center justify-center hover:scale-105 active:scale-95 transition-all"
            >
              <ZoomIn className="w-5 h-5 text-emerald-600" />
            </button>
            <button
              onClick={() => setZoom(Math.max(zoom - 1, 10))}
              className="w-11 h-11 bg-white shadow-lg rounded-2xl flex items-center justify-center hover:scale-105 active:scale-95 transition-all"
            >
              <ZoomOut className="w-5 h-5 text-emerald-600" />
            </button>
            <button className="w-11 h-11 bg-gradient-to-br from-emerald-500 to-teal-600 shadow-lg rounded-2xl flex items-center justify-center hover:scale-105 active:scale-95 transition-all">
              <Navigation className="w-5 h-5 text-white" />
            </button>
          </div>

          <div className="absolute bottom-4 left-4 bg-white/90 backdrop-blur-sm rounded-xl px-4 py-2 shadow-lg text-sm text-gray-600">
            Showing {DARWIN_BARS.length} bars in Darwin
          </div>
        </div>

        {/* List View */}
        <div className={`w-full lg:w-96 flex flex-col bg-white border-l border-gray-100 transition-all ${activeTab === 'map' && 'hidden lg:flex'}`}>
          <div className="p-4 border-b border-gray-100 flex items-center justify-between">
            <h2 className="font-semibold text-gray-900">Bars Near You</h2>
            <button onClick={() => setActiveTab(activeTab === 'list' ? 'map' : 'list')} className="lg:hidden p-2 hover:bg-gray-100 rounded-lg">
              <X className="w-5 h-5" />
            </button>
          </div>

          <div className="flex-1 overflow-y-auto">
            <div className="p-4 space-y-3">
              {DARWIN_BARS.map((bar) => (
                <button
                  key={bar.id}
                  onClick={() => {
                    setSelectedBar(bar);
                    setActiveTab('map');
                  }}
                  className={`w-full text-left rounded-xl overflow-hidden transition-all ${selectedBar?.id === bar.id ? 'ring-2 ring-emerald-500' : ''} hover:shadow-md`}
                >
                  <div className="flex gap-3 p-3 bg-gray-50 hover:bg-gray-100">
                    <div className="w-20 h-20 rounded-lg flex-shrink-0 overflow-hidden bg-gray-200">
                      <img src={bar.photos[0]} alt={bar.name} className="w-full h-full object-cover" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <h3 className="font-semibold text-gray-900 truncate">{bar.name}</h3>
                      <div className="flex items-center gap-1 mt-1">
                        <Star className="w-4 h-4 text-amber-500 fill-amber-500" />
                        <span className="text-sm font-semibold text-gray-900">{bar.rating}</span>
                        <span className="text-xs text-gray-500">({bar.reviewCount})</span>
                      </div>
                      <p className="text-xs text-gray-500 mt-1 truncate">{bar.address.split(',')[0]}</p>
                      <div className="flex items-center gap-2 mt-2">
                        <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${bar.openNow ? 'bg-emerald-100 text-emerald-700' : 'bg-gray-100 text-gray-600'}`}>
                          {bar.openNow ? 'Open Now' : 'Closed'}
                        </span>
                        <span className="text-xs text-gray-500">{bar.distance} km</span>
                      </div>
                    </div>
                  </div>
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Details Panel */}
        {selectedBar && (
          <div className={`w-full lg:w-80 flex flex-col bg-white border-l border-gray-100 transition-all ${activeTab === 'map' && 'hidden lg:flex'}`}>
            <div className="p-4 border-b border-gray-100 flex items-center justify-between">
              <h3 className="font-semibold text-gray-900 truncate">{selectedBar.name}</h3>
            </div>

            <div className="flex-1 overflow-y-auto">
              <div className="aspect-video bg-gray-200 overflow-hidden">
                <img src={selectedBar.photos[0]} alt={selectedBar.name} className="w-full h-full object-cover" />
              </div>

              <div className="p-4 space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-4">
                    <div className="flex items-center gap-1">
                      <Star className="w-5 h-5 text-amber-500 fill-amber-500" />
                      <span className="font-bold text-gray-900">{selectedBar.rating}</span>
                      <span className="text-sm text-gray-500">({selectedBar.reviewCount} reviews)</span>
                    </div>
                  </div>
                </div>

                <div className="space-y-2">
                  <div className="flex items-center gap-2 text-gray-600">
                    <MapPinIcon className="w-4 h-4" />
                    <span className="text-sm">{selectedBar.address}</span>
                  </div>
                  <div className={`text-sm px-3 py-1.5 rounded-lg inline-block font-medium ${selectedBar.openNow ? 'bg-emerald-100 text-emerald-700' : 'bg-gray-100 text-gray-600'}`}>
                    {selectedBar.openNow ? 'Open Now' : 'Currently Closed'}
                  </div>
                </div>

                <div className="pt-2 border-t border-gray-100 space-y-2">
                  <p className="text-xs uppercase tracking-wider font-semibold text-gray-500">What people say</p>
                  <div className="space-y-2 text-sm text-gray-600">
                    <p className="leading-relaxed">Great atmosphere with friendly staff. Amazing cocktails and a lively crowd. Must visit when in Darwin!</p>
                  </div>
                </div>

                <div className="flex gap-2 pt-4">
                  <button className="flex-1 flex items-center justify-center gap-2 bg-emerald-500 text-white py-2.5 rounded-lg font-semibold hover:bg-emerald-600 transition-colors">
                    <MessageCircle className="w-4 h-4" />
                    Message
                  </button>
                  <button className="flex-1 flex items-center justify-center gap-2 bg-gray-100 text-gray-900 py-2.5 rounded-lg font-semibold hover:bg-gray-200 transition-colors">
                    <Users className="w-4 h-4" />
                    {Math.floor(Math.random() * 12)} Here
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      <div className="px-6 py-4 bg-gray-50 border-t border-gray-100 text-sm text-gray-600">
        With denormalized Google Place data in the bars table, the Flutter app fetches ratings, reviews, photos, and hours directly. No extra API calls needed!
      </div>
    </div>
  );
}
