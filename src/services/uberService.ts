import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
);

interface PriceEstimate {
  product_id: string;
  product_name: string;
  currency_code: string;
  display_name: string;
  estimate: string;
  low_estimate: number;
  high_estimate: number;
  surge_multiplier: number;
  duration: number;
  distance: number;
}

interface RideEstimates {
  prices: PriceEstimate[];
}

interface RideRequest {
  ride_id: string;
  status: string;
  pickup: {
    latitude: number;
    longitude: number;
    address?: string;
  };
  dropoff: {
    latitude: number;
    longitude: number;
    address?: string;
  };
  driver?: {
    name: string;
    rating: number;
    phone_number: string;
    vehicle: {
      make: string;
      model: string;
      license_plate: string;
    };
  };
}

export async function getUberEstimates(
  pickupLat: number,
  pickupLng: number,
  dropoffLat: number,
  dropoffLng: number
): Promise<PriceEstimate[]> {
  const { data, error } = await supabase.functions.invoke('uber-rides', {
    body: {
      action: 'get_estimates',
      pickup_latitude: pickupLat,
      pickup_longitude: pickupLng,
      dropoff_latitude: dropoffLat,
      dropoff_longitude: dropoffLng,
    },
  });

  if (error) throw new Error(`Failed to get Uber estimates: ${error.message}`);
  return data.prices || [];
}

export async function requestUberRide(
  pickupLat: number,
  pickupLng: number,
  dropoffLat: number,
  dropoffLng: number,
  productId: string
): Promise<RideRequest> {
  const { data, error } = await supabase.functions.invoke('uber-rides', {
    body: {
      action: 'request_ride',
      pickup_latitude: pickupLat,
      pickup_longitude: pickupLng,
      dropoff_latitude: dropoffLat,
      dropoff_longitude: dropoffLng,
      product_id: productId,
    },
  });

  if (error) throw new Error(`Failed to request Uber ride: ${error.message}`);
  return data;
}

export async function getRideStatus(rideId: string): Promise<RideRequest> {
  const { data, error } = await supabase.functions.invoke('uber-rides', {
    body: {
      action: 'get_status',
      ride_id: rideId,
    },
  });

  if (error) throw new Error(`Failed to get ride status: ${error.message}`);
  return data;
}
