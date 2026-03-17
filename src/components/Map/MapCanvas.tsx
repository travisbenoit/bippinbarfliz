import { useRef, useEffect, useState, useCallback } from 'react';
import L from 'leaflet';
import { Layers, Navigation, MapPin } from 'lucide-react';
import type { MapSwarm, MapUserProfile } from '../../hooks/useMapData';
import type { RealTimeVenue } from '../../services/locationService';

type TonightStatus = 'going_out' | 'maybe' | 'staying_in' | null;
type TabType = 'swarms' | 'people' | 'places' | 'hotspots';
type MapStyle = 'standard' | 'satellite' | 'dark';

interface Props {
  activeTab: TabType;
  mapCenter: [number, number];
  zoom: number;
  userLocation: { lat: number; lng: number } | null;
  searchCenter?: { lat: number; lng: number } | null;
  filteredSwarms: MapSwarm[];
  filteredUsers: MapUserProfile[];
  filteredVenues: RealTimeVenue[];
  venueUserCounts: Record<string, number>;
  onSwarmClick: (s: MapSwarm) => void;
  onUserClick: (u: MapUserProfile) => void;
  onVenueClick: (v: RealTimeVenue) => void;
  onMapMove: (center: [number, number], zoom: number, bounds?: { ne: [number, number]; sw: [number, number] }) => void;
  onRecenter: () => void;
  onSearchThisArea?: () => void;
}

const CATEGORY_ICONS: Record<string, { emoji: string; color: string }> = {
  club: { emoji: '\uD83C\uDFB5', color: '#8B5CF6' },
  brewery: { emoji: '\uD83C\uDF7A', color: '#F59E0B' },
  rooftop: { emoji: '\uD83C\uDF06', color: '#06B6D4' },
  lounge: { emoji: '\uD83C\uDF78', color: '#EC4899' },
  sports_bar: { emoji: '\uD83C\uDFC8', color: '#10B981' },
  bar: { emoji: '\uD83C\uDF7B', color: '#E91E63' },
  restaurant: { emoji: '\uD83C\uDF7D\uFE0F', color: '#6B7280' },
  nightclub: { emoji: '\uD83D\uDC83', color: '#A855F7' },
  pub: { emoji: '\uD83C\uDF7A', color: '#D97706' },
  wine_bar: { emoji: '\uD83C\uDF77', color: '#DC2626' },
};

function getCategoryIcon(category: string) {
  const data = CATEGORY_ICONS[category.toLowerCase()] || { emoji: '\uD83C\uDF7B', color: '#E91E63' };
  return data.emoji;
}

function getCategoryColor(category: string) {
  const data = CATEGORY_ICONS[category.toLowerCase()] || { emoji: '\uD83C\uDF7B', color: '#E91E63' };
  return data.color;
}

function getStatusColor(status: TonightStatus) {
  return status === 'going_out' ? 'bg-emerald-500' : status === 'maybe' ? 'bg-amber-500' : 'bg-gray-500';
}

const TILE_LAYERS: Record<MapStyle, { url: string; attribution: string }> = {
  standard: {
    url: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> &copy; <a href="https://carto.com/">CARTO</a>',
  },
  satellite: {
    url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    attribution: '&copy; Esri',
  },
  dark: {
    url: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> &copy; <a href="https://carto.com/">CARTO</a>',
  },
};

const STYLE_LABELS: Record<MapStyle, string> = {
  standard: 'Standard',
  satellite: 'Satellite',
  dark: 'Night',
};

function createDivIcon(html: string, className: string, size: [number, number]) {
  return L.divIcon({ html, className, iconSize: size, iconAnchor: [size[0] / 2, size[1] / 2] });
}

export default function MapCanvas({
  activeTab, mapCenter, zoom, userLocation, searchCenter,
  filteredSwarms, filteredUsers, filteredVenues, venueUserCounts,
  onSwarmClick, onUserClick, onVenueClick,
  onMapMove, onRecenter, onSearchThisArea,
}: Props) {
  const mapRef = useRef<L.Map | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const tileLayerRef = useRef<L.TileLayer | null>(null);
  const markersRef = useRef<L.LayerGroup>(L.layerGroup());
  const userMarkerRef = useRef<L.Marker | null>(null);
  const userCircleRef = useRef<L.CircleMarker | null>(null);
  const [mapStyle, setMapStyle] = useState<MapStyle>('standard');
  const [showStylePicker, setShowStylePicker] = useState(false);
  const isUserInteracting = useRef(false);
  const initializedRef = useRef(false);
  const onMapMoveRef = useRef(onMapMove);
  const onSearchThisAreaRef = useRef(onSearchThisArea);
  useEffect(() => { onMapMoveRef.current = onMapMove; }, [onMapMove]);
  useEffect(() => { onSearchThisAreaRef.current = onSearchThisArea; }, [onSearchThisArea]);

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return;

    const map = L.map(containerRef.current, {
      center: mapCenter,
      zoom,
      zoomControl: false,
      attributionControl: false,
    });

    const layer = TILE_LAYERS[mapStyle];
    tileLayerRef.current = L.tileLayer(layer.url, {
      attribution: layer.attribution,
      maxZoom: 19,
    }).addTo(map);

    markersRef.current.addTo(map);
    mapRef.current = map;
    initializedRef.current = true;

    map.on('movestart', () => { isUserInteracting.current = true; });
    map.on('moveend', () => {
      const c = map.getCenter();
      const bounds = map.getBounds();
      const ne = bounds.getNorthEast();
      const sw = bounds.getSouthWest();
      onMapMoveRef.current([c.lat, c.lng], map.getZoom(), {
        ne: [ne.lat, ne.lng],
        sw: [sw.lat, sw.lng]
      });
      setTimeout(() => { isUserInteracting.current = false; }, 200);
    });

    map.on('drag', () => {
      if (onSearchThisAreaRef.current) {
        onSearchThisAreaRef.current();
      }
    });

    return () => {
      map.remove();
      mapRef.current = null;
      initializedRef.current = false;
    };
  }, []);

  useEffect(() => {
    if (!mapRef.current || !tileLayerRef.current) return;
    const layer = TILE_LAYERS[mapStyle];
    tileLayerRef.current.setUrl(layer.url);
  }, [mapStyle]);

  useEffect(() => {
    if (!mapRef.current || isUserInteracting.current) return;
    const currentCenter = mapRef.current.getCenter();
    const currentZoom = mapRef.current.getZoom();
    const dist = Math.abs(currentCenter.lat - mapCenter[0]) + Math.abs(currentCenter.lng - mapCenter[1]);
    const zoomDiff = Math.abs(currentZoom - zoom);
    if (dist > 0.0001 && zoomDiff < 0.5) {
      mapRef.current.panTo(mapCenter, { animate: true });
    } else if (dist > 0.0001 || zoomDiff >= 0.5) {
      mapRef.current.setView(mapCenter, zoom, { animate: true });
    }
  }, [mapCenter, zoom]);

  useEffect(() => {
    const map = mapRef.current;
    if (!map) return;

    if (userLocation) {
      const latlng: L.LatLngExpression = [userLocation.lat, userLocation.lng];

      const isDarkMap = mapStyle === 'dark';
      const circleColor = isDarkMap ? 'rgba(0, 217, 255, 0.25)' : 'rgba(37, 99, 235, 0.2)';
      const circleFill = isDarkMap ? 'rgba(0, 217, 255, 0.1)' : 'rgba(37, 99, 235, 0.08)';

      if (!userCircleRef.current) {
        userCircleRef.current = L.circleMarker(latlng, {
          radius: 40,
          color: circleColor,
          fillColor: circleFill,
          fillOpacity: 1,
          weight: 0,
          interactive: false,
        }).addTo(map);
      } else {
        userCircleRef.current.setLatLng(latlng);
        userCircleRef.current.setStyle({ color: circleColor, fillColor: circleFill });
      }

      const darkClass = mapStyle === 'dark' ? ' dark-map' : '';
      const userIcon = createDivIcon(
        `<div class="user-location-dot${darkClass}">
          <div class="user-location-pulse"></div>
          <div class="user-location-core"></div>
        </div>`,
        'user-location-icon',
        [22, 22]
      );

      if (!userMarkerRef.current) {
        userMarkerRef.current = L.marker(latlng, { icon: userIcon, zIndexOffset: 1000, interactive: false }).addTo(map);
      } else {
        userMarkerRef.current.setLatLng(latlng);
        userMarkerRef.current.setIcon(userIcon);
      }
    }
  }, [userLocation, mapStyle]);

  const updateMarkers = useCallback(() => {
    const map = mapRef.current;
    if (!map) return;
    markersRef.current.clearLayers();

    if (activeTab === 'swarms') {
      filteredSwarms.forEach((swarm) => {
        const el = document.createElement('div');
        el.innerHTML = `
          <div class="map-marker-swarm">
            <div class="map-marker-swarm-glow"></div>
            <div class="map-marker-swarm-inner">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m12 3-1.912 5.813a2 2 0 0 1-1.275 1.275L3 12l5.813 1.912a2 2 0 0 1 1.275 1.275L12 21l1.912-5.813a2 2 0 0 1 1.275-1.275L21 12l-5.813-1.912a2 2 0 0 1-1.275-1.275L12 3Z"/></svg>
            </div>
            <div class="map-marker-badge">${swarm.memberCount}</div>
          </div>`;
        const icon = L.divIcon({ html: el.innerHTML, className: 'map-marker-container', iconSize: [52, 52], iconAnchor: [26, 26] });
        const marker = L.marker([swarm.lat, swarm.lng], { icon }).on('click', () => onSwarmClick(swarm));
        markersRef.current.addLayer(marker);
      });
    }

    if (activeTab === 'people') {
      filteredUsers.filter(u => u.tonightStatus === 'going_out').forEach((user) => {
        const statusClass = user.tonightStatus === 'going_out' ? 'status-green' : user.tonightStatus === 'maybe' ? 'status-amber' : 'status-gray';
        const avatarHtml = user.avatar_url
          ? `<img src="${user.avatar_url}" alt="${user.name}" class="map-avatar-img" />`
          : `<div class="map-avatar-fallback"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg></div>`;
        const el = `
          <div class="map-marker-user">
            ${avatarHtml}
            <div class="map-marker-status ${statusClass}"></div>
          </div>`;
        const icon = L.divIcon({ html: el, className: 'map-marker-container', iconSize: [44, 44], iconAnchor: [22, 22] });
        const marker = L.marker([user.lat, user.lng], { icon }).on('click', () => onUserClick(user));
        markersRef.current.addLayer(marker);
      });
    }

    if (activeTab === 'places') {
      filteredVenues.forEach((venue) => {
        const emoji = getCategoryIcon(venue.category);
        const color = getCategoryColor(venue.category);
        const count = venueUserCounts[venue.id] || 0;
        const countBadge = count > 0 ? `<div class="map-venue-count">${count}</div>` : '';
        const el = `
          <div class="map-marker-venue" style="border-color: ${color}; background: linear-gradient(135deg, ${color}15, ${color}08);">
            <span class="map-venue-emoji">${emoji}</span>
            ${countBadge}
          </div>`;
        const icon = L.divIcon({ html: el, className: 'map-marker-container', iconSize: [44, 44], iconAnchor: [22, 22] });
        const marker = L.marker([venue.lat, venue.lng], { icon }).on('click', () => onVenueClick(venue));
        markersRef.current.addLayer(marker);
      });
    }

    if (activeTab === 'hotspots') {
      filteredVenues.forEach((venue) => {
        const userCount = venueUserCounts[venue.id] || 0;
        const isHot = userCount > 0;
        const emoji = getCategoryIcon(venue.category);
        const color = getCategoryColor(venue.category);
        const el = isHot
          ? `<div class="map-marker-hotspot">
              <div class="map-marker-hotspot-glow"></div>
              <div class="map-marker-hotspot-inner">
                <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z"/></svg>
              </div>
              <div class="map-marker-badge map-marker-badge-hot">${userCount}</div>
            </div>`
          : `<div class="map-marker-venue" style="border-color: ${color}; background: linear-gradient(135deg, ${color}15, ${color}08);"><span class="map-venue-emoji">${emoji}</span></div>`;
        const icon = L.divIcon({ html: el, className: 'map-marker-container', iconSize: [isHot ? 52 : 44], iconAnchor: [isHot ? 26 : 22, isHot ? 26 : 22] });
        const marker = L.marker([venue.lat, venue.lng], { icon }).on('click', () => onVenueClick(venue));
        markersRef.current.addLayer(marker);
      });
    }
  }, [activeTab, filteredSwarms, filteredUsers, filteredVenues, venueUserCounts, onSwarmClick, onUserClick, onVenueClick]);

  useEffect(() => { updateMarkers(); }, [updateMarkers]);

  return (
    <div className="w-full h-full relative">
      <div ref={containerRef} className="w-full h-full" />

      <div className="absolute top-24 right-4 z-[1000] flex flex-col gap-2">
        <button
          onClick={() => mapRef.current?.zoomIn()}
          className="w-11 h-11 bg-white shadow-lg rounded-2xl flex items-center justify-center hover:scale-105 active:scale-95 transition-all"
        >
          <span className="text-[#E91E63] text-xl font-bold leading-none">+</span>
        </button>
        <button
          onClick={() => mapRef.current?.zoomOut()}
          className="w-11 h-11 bg-white shadow-lg rounded-2xl flex items-center justify-center hover:scale-105 active:scale-95 transition-all"
        >
          <span className="text-[#E91E63] text-xl font-bold leading-none">&minus;</span>
        </button>
        <button
          onClick={onRecenter}
          className="w-11 h-11 bg-gradient-to-br from-[#E91E63] to-[#C2185B] shadow-lg rounded-2xl flex items-center justify-center hover:scale-105 active:scale-95 transition-all"
        >
          <Navigation className="w-5 h-5 text-white" />
        </button>
        {onSearchThisArea && !searchCenter && (
          <button
            onClick={onSearchThisArea}
            className="w-11 h-11 bg-white shadow-lg rounded-2xl flex items-center justify-center hover:scale-105 active:scale-95 transition-all"
            title="Search this area"
          >
            <MapPin className="w-5 h-5 text-gray-600" />
          </button>
        )}
        <div className="relative">
          <button
            onClick={() => setShowStylePicker(!showStylePicker)}
            className="w-11 h-11 bg-white shadow-lg rounded-2xl flex items-center justify-center hover:scale-105 active:scale-95 transition-all"
          >
            <Layers className="w-5 h-5 text-gray-600" />
          </button>
          {showStylePicker && (
            <div className="absolute right-full mr-2 top-0 bg-white rounded-2xl shadow-xl border border-gray-100 overflow-hidden animate-fade-in w-36">
              {(Object.keys(TILE_LAYERS) as MapStyle[]).map((style) => (
                <button
                  key={style}
                  onClick={() => { setMapStyle(style); setShowStylePicker(false); }}
                  className={`w-full px-4 py-3 text-left text-sm font-medium transition-colors flex items-center gap-2 ${
                    mapStyle === style
                      ? 'bg-[#E91E63]/10 text-[#E91E63]'
                      : 'text-gray-700 hover:bg-gray-50'
                  }`}
                >
                  <div className={`w-2 h-2 rounded-full ${mapStyle === style ? 'bg-[#E91E63]' : 'bg-gray-300'}`} />
                  {STYLE_LABELS[style]}
                </button>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export { getCategoryIcon, getStatusColor };
export type { TonightStatus, TabType, MapStyle };
