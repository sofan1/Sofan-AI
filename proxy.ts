import { NextResponse } from 'next/server';

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|api).*)'],
};

export function proxy(req) {
  const url = req.nextUrl.clone();
  url.pathname = '/api/proxy' + url.pathname;
  return NextResponse.rewrite(url);
}
