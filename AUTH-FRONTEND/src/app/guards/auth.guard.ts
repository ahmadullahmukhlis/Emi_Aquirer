import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';

export const AuthGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  // Since isLoggedIn is a Signal, we call it as a function
  if (authService.isLoggedIn()) {
    return true;
  }

  return router.parseUrl('/login');
};
