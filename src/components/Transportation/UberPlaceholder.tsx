import { Car, ExternalLink } from 'lucide-react';

interface UberPlaceholderProps {
  currentLocation?: string;
  currentLatitude?: number;
  currentLongitude?: number;
  destination?: string;
  destinationLatitude?: number;
  destinationLongitude?: number;
  venues?: { id: string; name: string; latitude: number; longitude: number; address: string }[];
}

function buildUberDeepLink(props: UberPlaceholderProps): string {
  const params = new URLSearchParams();

  if (props.currentLatitude && props.currentLongitude) {
    params.set('pickup[latitude]', String(props.currentLatitude));
    params.set('pickup[longitude]', String(props.currentLongitude));
    if (props.currentLocation) {
      params.set('pickup[nickname]', props.currentLocation);
    }
  } else {
    params.set('pickup', 'my_location');
  }

  if (props.destinationLatitude && props.destinationLongitude) {
    params.set('dropoff[latitude]', String(props.destinationLatitude));
    params.set('dropoff[longitude]', String(props.destinationLongitude));
    if (props.destination) {
      params.set('dropoff[nickname]', props.destination);
    }
  }

  const query = params.toString();
  return `https://m.uber.com/ul/?${query}`;
}

export default function UberPlaceholder(props: UberPlaceholderProps) {
  const {
    currentLocation = 'Your location',
    destination,
  } = props;

  const deepLink = buildUberDeepLink(props);

  return (
    <a
      href={deepLink}
      target="_blank"
      rel="noopener noreferrer"
      className="block bg-white rounded-2xl shadow-sm p-5 border border-gray-100 hover:border-gray-300 hover:shadow-md transition-all group"
    >
      <div className="flex items-center gap-3">
        <div className="w-12 h-12 bg-black rounded-xl flex items-center justify-center group-hover:scale-105 transition-transform">
          <Car size={24} className="text-white" />
        </div>
        <div className="flex-1 min-w-0">
          <h3 className="font-bold text-gray-900">Ride to the venue</h3>
          <p className="text-sm text-gray-500">Open Uber to request a ride</p>
        </div>
        <ExternalLink size={18} className="text-gray-400 group-hover:text-gray-700 transition-colors flex-shrink-0" />
      </div>
      <div className="mt-3 flex items-center gap-2 text-xs text-gray-400">
        <span>From: {currentLocation}</span>
        {destination && <span>To: {destination}</span>}
      </div>
    </a>
  );
}
