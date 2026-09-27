import { Component, inject } from '@angular/core';
import { DynamicFormBuilder } from '../../../components/ui/dynamic-form-builder/dynamic-form-builder';
import { DynamicField } from '../../../models/fomrBuilderModel';
import { ApiService } from '../../../services/api/api.service';

@Component({
  selector: 'app-mfa',
  standalone: true,
  imports: [DynamicFormBuilder],
  templateUrl: './mfa.html',
  styleUrl: './mfa.css',
})
export class MfaPage {
  private api = inject(ApiService);

  mfaSetupResult: any = null;
  emailCodeResult: any = null;
  message: string = '';

  mfaVerifyFields: DynamicField[] = [
    { type: 'text', name: 'code', label: 'MFA Code', required: true },
  ];

  emailVerifyFields: DynamicField[] = [
    { type: 'text', name: 'code', label: 'Email Verification Code', required: true },
  ];

  setupMfa = () => {
    this.message = '';
    this.api.post('/account/mfa/setup', {}).subscribe({
      next: (res: any) => {
        this.mfaSetupResult = res?.data ?? res;
      },
    });
  };

  verifyMfa = (payload: any) => {
    this.message = '';
    this.api.post('/account/mfa/verify', payload).subscribe({
      next: () => (this.message = 'MFA enabled'),
    });
  };

  disableMfa = (payload: any) => {
    this.message = '';
    this.api.post('/account/mfa/disable', payload).subscribe({
      next: () => (this.message = 'MFA disabled'),
    });
  };

  requestEmailCode = () => {
    this.message = '';
    this.api.post('/account/email/verify/request', {}).subscribe({
      next: (res: any) => {
        this.emailCodeResult = res?.data ?? res;
      },
    });
  };

  confirmEmail = (payload: any) => {
    this.message = '';
    this.api.post('/account/email/verify/confirm', payload).subscribe({
      next: () => (this.message = 'Email verified'),
    });
  };
}
