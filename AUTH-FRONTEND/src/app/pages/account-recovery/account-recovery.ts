import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';

@Component({
  selector: 'app-account-recovery',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './account-recovery.html',
  styleUrl: './account-recovery.css',
})
export class AccountRecovery {
  private readonly http = inject(HttpClient);
  private readonly route = inject(ActivatedRoute);
  readonly mode = this.route.snapshot.routeConfig?.path ?? 'forgot-password';
  email = '';
  password = '';
  confirmPassword = '';
  status = '';
  error = '';
  loading = false;
  private readonly apiUrl = import.meta.env.NG_APP_LOGIN_URL.replace(/\/$/, '');
  private readonly token = this.route.snapshot.queryParamMap.get('token') ?? '';

  submit() {
    this.status = ''; this.error = '';
    if ((this.mode === 'reset-password' && (!this.token || this.password.length < 12 || this.password !== this.confirmPassword)) || (this.mode === 'verify-email' && !this.token)) {
      this.error = 'Check the secure link and form values, then try again.'; return;
    }
    this.loading = true;
    const endpoint = this.mode === 'forgot-password' ? '/account/forgot-password' : this.mode === 'request-verification' ? '/account/request-email-verification' : this.mode === 'verify-email' ? '/account/verify-email' : '/account/reset-password';
    const body = this.mode === 'forgot-password' || this.mode === 'request-verification' ? { email: this.email } : this.mode === 'verify-email' ? { token: this.token } : { token: this.token, password: this.password };
    this.http.post<any>(`${this.apiUrl}${endpoint}`, body).subscribe({
      next: response => { this.loading = false; response.status ? this.status = response.message : this.error = response.message; },
      error: error => { this.loading = false; this.error = error.error?.message || 'The request could not be completed.'; },
    });
  }
}
