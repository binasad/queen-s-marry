import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

// Define public routes that don't require authentication
const publicRoutes = ['/login', '/set-password', '/forgot-password', '/reset-password'];

// Define routes that should be completely public (API routes, static files, etc.)
const ignoredRoutes = ['/_next', '/api', '/favicon.ico', '/images', '/assets'];

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Skip middleware for ignored routes
  if (ignoredRoutes.some(route => pathname.startsWith(route))) {
    return NextResponse.next();
  }

  // Skip middleware for public routes
  if (publicRoutes.some(route => pathname === route || pathname.startsWith(route + '/'))) {
    return NextResponse.next();
  }

  // Check for authentication token in cookies or check auth-storage cookie
  // Note: We're checking cookies since localStorage is not available in middleware
  const authStorage = request.cookies.get('auth-storage');
  
  // For client-side Zustand persist, the token is in localStorage
  // We'll rely on the AuthGuard component for the actual check
  // But we can add a basic cookie-based check for extra security
  
  // If there's no auth cookie at all, redirect to login
  // The actual token validation happens in AuthGuard
  
  // For now, let middleware pass through and let AuthGuard handle it
  // This is because Zustand persist uses localStorage, not cookies
  
  return NextResponse.next();
}

export const config = {
  matcher: [
    /*
     * Match all request paths except:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public folder
     */
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
};
