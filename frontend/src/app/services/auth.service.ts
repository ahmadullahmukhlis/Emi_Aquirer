import { Injectable, inject, signal, computed } from '@angular/core';
import { Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { jwtDecode } from 'jwt-decode';
import { Observable, of } from 'rxjs';
import { tap, catchError } from 'rxjs/operators';
import { ApiService } from './api/api.service';
import { ClientContextService } from './client-context.service';

export interface CurrentUser {
  name: string;
  email: string;
  role: string;
  initials: string;
}

@Injectable({
  providedIn: 'root',
})
export class AuthService {
  // Use inject() for modern DI in field initializers
  private readonly router = inject(Router);
  private readonly http = inject(HttpClient);
  private readonly api = inject(ApiService);
  private readonly clientContext = inject(ClientContextService);

  // Signal to track the current token state reactively
  private readonly _accessToken = signal<string | null>(localStorage.getItem('accessToken'));

  /**
   * Computed signal to check if the user is logged in.
   * Components can use authService.isLoggedIn() reactively.
   */
  readonly isLoggedIn = computed(() => {
    const token = this._accessToken();
    return !!token && !this.isTokenExpired(token);
  });

  readonly currentUser = computed<CurrentUser>(() => this.decodeCurrentUser(this._accessToken()));

  /* ============================
     TOKEN STORAGE
  ============================ */

  setTokens(accessToken: string, refreshToken: string) {
    localStorage.setItem('accessToken', accessToken);
    localStorage.setItem('refreshToken', refreshToken);
    this._accessToken.set(accessToken); // Update signal
  }

  getAccessToken(): string | null {
    return this._accessToken();
  }

  getRefreshToken(): string | null {
    return localStorage.getItem('refreshToken');
  }

  private decodeCurrentUser(token: string | null): CurrentUser {
    const fallback: CurrentUser = { name: 'Signed-in user', email: '', role: 'Administrator', initials: 'SU' };
    if (!token) return fallback;

    try {
      const claims = jwtDecode<Record<string, unknown>>(token);
      const pick = (...keys: string[]) => {
        for (const key of keys) {
          const value = claims[key];
          if (typeof value === 'string' && value.trim()) return value.trim();
        }
        return '';
      };
      const name = pick('name', 'preferred_username', 'username', 'sub') || fallback.name;
      const email = pick('email');
      const roleValue = claims['role'] ?? claims['roles'];
      const role = Array.isArray(roleValue)
        ? String(roleValue[0] ?? fallback.role)
        : typeof roleValue === 'string' && roleValue ? roleValue : fallback.role;
      const initials = name
        .split(/\s+/)
        .slice(0, 2)
        .map((part) => part.charAt(0).toUpperCase())
        .join('') || fallback.initials;
      return { name, email, role, initials };
    } catch {
      return fallback;
    }
  }

  clearTokens() {
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    this._accessToken.set(null);
    this.clientContext.clearContext();
  }

  /* ============================
     LOGIN STATUS
  ============================ */

  isTokenExpired(token: string): boolean {
    try {
      const decoded: any = jwtDecode(token);
      return decoded.exp < Date.now() / 1000;
    } catch {
      return true;
    }
  }

  /* ============================
     REFRESH TOKEN
  ============================ */

  refreshToken(): Observable<any> {
    const refreshToken = this.getRefreshToken();
    const clientId = this.clientContext.getClientId();
    const clientAssertion = this.clientContext.getClientAssertion();

    if (!refreshToken) {
      this.logout();
      return of(null);
    }

    const params = { refreshToken };
    return this.http
      .post<any>(`${import.meta.env.NG_APP_API_URL}/refresh`, null, {
        params,
        headers: {
          'X-Client-Id': clientId ?? '',
          'X-Client-Assertion': clientAssertion ?? '',
        },
      })
      .pipe(
        tap((res: any) => {
          const data = res?.data ?? res;
          if (data?.accessToken && data?.refreshToken) {
            this.setTokens(data.accessToken, data.refreshToken);
          }
        }),
        catchError((error) => {
          console.error('Refresh token failed:', error);
          this.logout();
          return of(null);
        }),
      );
  }

  /* ============================
     LOGOUT
  ============================ */

  logout() {
    const refreshToken = this.getRefreshToken();
    const clientId = this.clientContext.getClientId();
    const clientAssertion = this.clientContext.getClientAssertion();

    if (refreshToken && clientId && clientAssertion) {
      this.http
        .post<any>(`${import.meta.env.NG_APP_API_URL}/logout`, null, {
          params: { refreshToken },
          headers: {
            'X-Client-Id': clientId,
            'X-Client-Assertion': clientAssertion,
          },
        })
        .subscribe({
          complete: () => {
            this.clearTokens();
            this.router.navigate(['/login']);
          },
          error: () => {
            this.clearTokens();
            this.router.navigate(['/login']);
          },
        });
      return;
    }

    this.clearTokens();
    this.router.navigate(['/login']);
  }
}
