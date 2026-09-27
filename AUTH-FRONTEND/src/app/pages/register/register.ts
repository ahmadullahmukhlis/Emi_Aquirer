import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { Router, RouterLink } from '@angular/router';

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [ReactiveFormsModule, RouterLink],
  templateUrl: './register.html',
  styleUrl: './register.css',
})
export class Register {
  private fb = inject(FormBuilder);
  private http = inject(HttpClient);
  private router = inject(Router);
  form = this.fb.nonNullable.group({
    firstName: ['', [Validators.required]], lastName: ['', [Validators.required]],
    username: ['', [Validators.required, Validators.minLength(3)]],
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(8)]],
    confirmPassword: ['', [Validators.required]],
  });
  loading = false; error = ''; success = '';
  submit() {
    if (this.form.invalid) { this.form.markAllAsTouched(); return; }
    const value = this.form.getRawValue();
    if (value.password !== value.confirmPassword) { this.error = 'Passwords do not match.'; return; }
    this.loading = true; this.error = '';
    const user = { username: value.username, firstName: value.firstName, lastName: value.lastName, email: value.email, password: value.password };
    const body = new FormData();
    body.append('user', new Blob([JSON.stringify(user)], { type: 'application/json' }));
    this.http.post<any>(`${(import.meta.env.NG_APP_LOGIN_URL || '').replace(/\/$/, '')}/users`, body).subscribe({
      next: () => { this.loading = false; this.success = 'Account created. Sign in to continue business verification.'; setTimeout(() => this.router.navigate(['/login']), 900); },
      error: e => { this.loading = false; this.error = e?.error?.message || 'Registration failed. Please try again.'; },
    });
  }
  continueWithGoogle() {
    const url = (import.meta.env.NG_APP_GOOGLE_AUTH_URL || '').trim();
    if (url) window.location.href = url;
    else this.error = 'Google sign-in is not configured yet. Set NG_APP_GOOGLE_AUTH_URL after registering the Google OAuth callback.';
  }
}
