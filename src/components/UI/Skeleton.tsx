/**
 * Skeleton loading placeholders — Bumble/Tinder-tier shimmer effect.
 * Use these instead of spinners for layout-preserving loading states.
 */

interface SkeletonProps {
  className?: string;
}

export function Skeleton({ className = '' }: SkeletonProps) {
  return (
    <div
      className={`skeleton-shimmer rounded-xl ${className}`}
    />
  );
}

export function AvatarSkeleton({ size = 'md' }: { size?: 'sm' | 'md' | 'lg' }) {
  const sizes = { sm: 'w-10 h-10', md: 'w-14 h-14', lg: 'w-20 h-20' };
  return <div className={`skeleton-shimmer rounded-full ${sizes[size]}`} />;
}

export function TextSkeleton({ lines = 1, widths }: { lines?: number; widths?: string[] }) {
  const defaultWidths = ['w-3/4', 'w-1/2', 'w-5/6', 'w-2/3'];
  return (
    <div className="space-y-2.5">
      {Array.from({ length: lines }).map((_, i) => (
        <div
          key={i}
          className={`skeleton-shimmer h-3.5 rounded-full ${widths?.[i] || defaultWidths[i % defaultWidths.length]}`}
        />
      ))}
    </div>
  );
}

export function CardSkeleton() {
  return (
    <div className="bg-white rounded-2xl p-5 shadow-sm space-y-4">
      <div className="flex items-center gap-3">
        <AvatarSkeleton />
        <div className="flex-1 space-y-2">
          <Skeleton className="h-4 w-32" />
          <Skeleton className="h-3 w-20" />
        </div>
      </div>
      <TextSkeleton lines={2} />
      <div className="flex gap-2">
        <Skeleton className="h-7 w-16 rounded-full" />
        <Skeleton className="h-7 w-20 rounded-full" />
        <Skeleton className="h-7 w-14 rounded-full" />
      </div>
    </div>
  );
}

export function ProfileCardSkeleton() {
  return (
    <div className="bg-white rounded-2xl overflow-hidden shadow-sm">
      <Skeleton className="h-40 rounded-none" />
      <div className="p-5 space-y-4 -mt-10 relative">
        <div className="flex justify-center">
          <div className="skeleton-shimmer w-20 h-20 rounded-full border-4 border-white" />
        </div>
        <div className="text-center space-y-2">
          <Skeleton className="h-5 w-32 mx-auto" />
          <Skeleton className="h-3 w-24 mx-auto" />
        </div>
        <div className="flex justify-center gap-2">
          <Skeleton className="h-8 w-24 rounded-full" />
          <Skeleton className="h-8 w-24 rounded-full" />
        </div>
      </div>
    </div>
  );
}

export function VenueCardSkeleton() {
  return (
    <div className="bg-white rounded-2xl overflow-hidden shadow-sm">
      <Skeleton className="h-32 rounded-none" />
      <div className="p-4 space-y-2">
        <Skeleton className="h-4 w-40" />
        <Skeleton className="h-3 w-28" />
        <div className="flex gap-2 pt-1">
          <Skeleton className="h-6 w-14 rounded-full" />
          <Skeleton className="h-6 w-18 rounded-full" />
        </div>
      </div>
    </div>
  );
}

export function HomeSkeleton() {
  return (
    <div className="space-y-6 p-4 animate-fade-in">
      {/* Profile card skeleton */}
      <div className="bg-gradient-to-br from-pink-100 to-orange-50 rounded-2xl p-6 space-y-4">
        <div className="flex items-center gap-4">
          <AvatarSkeleton size="lg" />
          <div className="flex-1 space-y-2">
            <Skeleton className="h-5 w-36" />
            <Skeleton className="h-3 w-24" />
          </div>
        </div>
        <div className="grid grid-cols-3 gap-3">
          {[1, 2, 3].map(i => (
            <Skeleton key={i} className="h-16 rounded-xl" />
          ))}
        </div>
      </div>

      {/* Quick actions skeleton */}
      <div className="grid grid-cols-2 gap-3">
        {[1, 2, 3, 4].map(i => (
          <Skeleton key={i} className="h-14 rounded-xl" />
        ))}
      </div>

      {/* Tonight's scene skeleton */}
      <div className="space-y-3">
        <Skeleton className="h-5 w-32" />
        {[1, 2, 3].map(i => (
          <CardSkeleton key={i} />
        ))}
      </div>
    </div>
  );
}
