import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { HttpClient } from '@angular/common/http';
import { RouterLink } from '@angular/router';

interface LoginResponse {
  status: boolean;
  message: string;
  data?: { accessToken?: string; refreshToken?: string };
}

@Component({
  selector: 'app-login',
  templateUrl: './login.html',
  imports: [ReactiveFormsModule, RouterLink],
})
export class Login implements OnInit {
  loginForm: FormGroup;
  isLoading = false;
  errorMessage = '';
  showPassword = false;

  constructor(
    private fb: FormBuilder,
    private http: HttpClient,
    private authService: AuthService,
    private router: Router,
  ) {
    this.loginForm = this.fb.group({
      username: ['', [Validators.required]],
      password: ['', [Validators.required, Validators.minLength(8)]],
    });
  }

  ngOnInit(): void {
    if (this.authService.isLoggedIn()) {
      this.router.navigate(['/gateway/transactions']);
    } else {
      this.authService.clearTokens();
    }
  }

  login(): void {
    if (this.loginForm.invalid || this.isLoading) return;

    this.isLoading = true;
    this.errorMessage = '';
    this.loginForm.disable(); // ✅ prevent double submit

    const { username, password } = this.loginForm.value;
    const loginUrl = import.meta.env.NG_APP_LOGIN_URL;
    // The backend LoginDto requires a JSON request body.
    const credentials = { username, password };
    this.http.post<LoginResponse>(`${loginUrl.replace(/\/$/, '')}/login`, credentials).subscribe({
      next: (res) => {
        this.isLoading = false;
        this.loginForm.enable(); // ✅ re-enable form
        if (!res.status) {
          this.errorMessage = res.message || 'Invalid username or password.';
          return;
        }

        const accessToken = res.data?.accessToken;
        const refreshToken = res.data?.refreshToken;
 
        if (!accessToken) {
          this.errorMessage = 'Invalid server response';
          return;
        }

        this.authService.setTokens(accessToken, refreshToken ?? '');
        this.router.navigate(['/gateway/transactions']);
      },

      error: (err) => {
        this.isLoading = false;
        this.loginForm.enable(); // ✅ re-enable form
        this.errorMessage = err.error?.message || 'Server error. Try again.';
        console.error('Login error:', err);
      },
    });
  }

  togglePasswordVisibility(): void {
    this.showPassword = !this.showPassword;
  }

  continueWithGoogle(): void {
    const url = (import.meta.env.NG_APP_GOOGLE_AUTH_URL || '').trim();
    if (url) window.location.href = url;
    else this.errorMessage = 'Google sign-in is not configured yet. Set NG_APP_GOOGLE_AUTH_URL for production.';
  }

  private markFormGroupTouched(formGroup: FormGroup): void {
    Object.values(formGroup.controls).forEach((control) => {
      control.markAsTouched();
      if (control instanceof FormGroup) {
        this.markFormGroupTouched(control);
      }
    });
  }

  get usernameControl() {
    return this.loginForm.get('username');
  }

  get passwordControl() {
    return this.loginForm.get('password');
  }

}
