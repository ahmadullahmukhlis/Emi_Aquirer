import { Component, inject } from '@angular/core';
import { DynamicFormBuilder } from '../../../components/ui/dynamic-form-builder/dynamic-form-builder';
import { DynamicField } from '../../../models/fomrBuilderModel';
import { HttpClient, HttpParams, HttpHeaders } from '@angular/common/http';
import { JwtSignService } from '../../../services/crypto/jwt-sign.service';

@Component({
  selector: 'app-oauth-tools',
  standalone: true,
  imports: [DynamicFormBuilder],
  templateUrl: './oauth.html',
  styleUrl: './oauth.css',
})
export class OAuthTools {
  private http = inject(HttpClient);
  private jwtSign = inject(JwtSignService);

  authorizeUrl: string = '';
  tokenResponse: any = null;
  introspectResponse: any = null;
  errorMessage: string = '';
  generatedAssertion: string = '';

  authorizeFields: DynamicField[] = [
    { type: 'text', name: 'clientId', label: 'Client ID', required: true },
    { type: 'text', name: 'redirectUri', label: 'Redirect URI', required: true },
    { type: 'text', name: 'scope', label: 'Scope (space separated)', required: false },
    { type: 'text', name: 'state', label: 'State', required: false },
    { type: 'text', name: 'codeChallenge', label: 'Code Challenge', required: false },
    { type: 'text', name: 'codeChallengeMethod', label: 'Code Challenge Method', required: false },
  ];

  clientCredentialsFields: DynamicField[] = [
    { type: 'text', name: 'clientId', label: 'Client ID', required: true },
    { type: 'textarea', name: 'clientAssertion', label: 'Client Assertion JWT', required: true },
    { type: 'text', name: 'scope', label: 'Scope (optional)', required: false },
  ];

  authCodeFields: DynamicField[] = [
    { type: 'text', name: 'clientId', label: 'Client ID', required: true },
    { type: 'textarea', name: 'clientAssertion', label: 'Client Assertion JWT', required: true },
    { type: 'text', name: 'code', label: 'Authorization Code', required: true },
    { type: 'text', name: 'redirectUri', label: 'Redirect URI', required: true },
    { type: 'text', name: 'codeVerifier', label: 'Code Verifier', required: false },
  ];

  introspectFields: DynamicField[] = [
    { type: 'textarea', name: 'token', label: 'Token', required: true },
    { type: 'text', name: 'clientId', label: 'Client ID', required: true },
    { type: 'textarea', name: 'clientAssertion', label: 'Client Assertion JWT', required: true },
  ];

  assertionFields: DynamicField[] = [
    { type: 'text', name: 'clientId', label: 'Client ID', required: true },
    { type: 'text', name: 'audience', label: 'Audience', required: true },
    { type: 'number', name: 'expiresIn', label: 'Expires In (seconds)', required: true, defaultValue: 300 },
    { type: 'textarea', name: 'privateKey', label: 'Private Key (PEM)', required: true },
  ];

  buildAuthorizeUrl = (payload: any) => {
    const base = import.meta.env.NG_APP_API_URL?.replace(/\/$/, '') ?? '';
    const params = new URLSearchParams();
    params.set('response_type', 'code');
    params.set('client_id', payload.clientId);
    params.set('redirect_uri', payload.redirectUri);
    if (payload.scope) params.set('scope', payload.scope);
    if (payload.state) params.set('state', payload.state);
    if (payload.codeChallenge) params.set('code_challenge', payload.codeChallenge);
    if (payload.codeChallengeMethod) params.set('code_challenge_method', payload.codeChallengeMethod);
    this.authorizeUrl = `${base}/oauth2/authorize?${params.toString()}`;
  };

  submitClientCredentials = (payload: any) => {
    this.errorMessage = '';
    const base = import.meta.env.NG_APP_API_URL?.replace(/\/$/, '') ?? '';
    const body = new HttpParams()
      .set('grant_type', 'client_credentials')
      .set('client_id', payload.clientId)
      .set('scope', payload.scope ?? '');

    const headers = new HttpHeaders()
      .set('X-Client-Id', payload.clientId)
      .set('X-Client-Assertion', payload.clientAssertion)
      .set('Content-Type', 'application/x-www-form-urlencoded');

    this.http.post<any>(`${base}/oauth2/token`, body, { headers }).subscribe({
      next: (res) => (this.tokenResponse = res),
      error: (err) => (this.errorMessage = err?.error?.message || 'Request failed'),
    });
  };

  submitAuthCode = (payload: any) => {
    this.errorMessage = '';
    const base = import.meta.env.NG_APP_API_URL?.replace(/\/$/, '') ?? '';
    let body = new HttpParams()
      .set('grant_type', 'authorization_code')
      .set('client_id', payload.clientId)
      .set('code', payload.code)
      .set('redirect_uri', payload.redirectUri);
    if (payload.codeVerifier) body = body.set('code_verifier', payload.codeVerifier);

    const headers = new HttpHeaders()
      .set('X-Client-Id', payload.clientId)
      .set('X-Client-Assertion', payload.clientAssertion)
      .set('Content-Type', 'application/x-www-form-urlencoded');

    this.http.post<any>(`${base}/oauth2/token`, body, { headers }).subscribe({
      next: (res) => (this.tokenResponse = res),
      error: (err) => (this.errorMessage = err?.error?.message || 'Request failed'),
    });
  };

  submitIntrospect = (payload: any) => {
    this.errorMessage = '';
    const base = import.meta.env.NG_APP_API_URL?.replace(/\/$/, '') ?? '';
    const body = new HttpParams().set('token', payload.token);
    const headers = new HttpHeaders()
      .set('X-Client-Id', payload.clientId)
      .set('X-Client-Assertion', payload.clientAssertion)
      .set('Content-Type', 'application/x-www-form-urlencoded');

    this.http.post<any>(`${base}/oauth2/introspect`, body, { headers }).subscribe({
      next: (res) => (this.introspectResponse = res),
      error: (err) => (this.errorMessage = err?.error?.message || 'Request failed'),
    });
  };

  generateAssertion = async (payload: any) => {
    this.errorMessage = '';
    try {
      const token = await this.jwtSign.signClientAssertion(
        payload.clientId,
        payload.audience,
        payload.privateKey,
        Number(payload.expiresIn || 300),
      );
      this.generatedAssertion = token;
    } catch (err: any) {
      this.errorMessage = err?.message || 'Failed to generate assertion';
    }
  };
}
