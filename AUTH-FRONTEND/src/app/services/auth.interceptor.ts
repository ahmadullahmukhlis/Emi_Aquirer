import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, throwError } from 'rxjs';
import { AuthService } from './auth.service';

export const AuthInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const router = inject(Router);
  
  // 1. Retrieve the token from storage (localStorage/Cookie)
  const token = localStorage.getItem('accessToken');

  // 2. Clone the request and add the Authorization header if token exists
  let authReq = req;
  if (token) {
    authReq = req.clone({
      setHeaders: {
        Authorization: `Bearer ${token}`
      }
    });
  }

  // 3. Handle the request and catch potential errors
  return next(authReq).pipe(
    catchError((error: HttpErrorResponse) => {
      // If 401 (Unauthorized) or 403 (Forbidden), clear token and redirect to login
      if (error.status === 401 || error.status === 403) {
        localStorage.removeItem('accessToken');
        localStorage.removeItem('refreshToken');
        router.navigate(['/login']);
      }
      return throwError(() => error);
    })
  );
};
