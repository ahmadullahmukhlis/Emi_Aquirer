import { Injectable, signal } from '@angular/core';

@Injectable({
  providedIn: 'root',
})
export class ClientContextService {
  private readonly CLIENT_ID_KEY = 'clientId';
  private readonly CLIENT_ASSERTION_KEY = 'clientAssertion';

  private _clientId = signal<string | null>(localStorage.getItem(this.CLIENT_ID_KEY));
  private _clientAssertion = signal<string | null>(
    localStorage.getItem(this.CLIENT_ASSERTION_KEY),
  );

  setContext(clientId: string, clientAssertion: string) {
    localStorage.setItem(this.CLIENT_ID_KEY, clientId);
    localStorage.setItem(this.CLIENT_ASSERTION_KEY, clientAssertion);
    this._clientId.set(clientId);
    this._clientAssertion.set(clientAssertion);
  }

  clearContext() {
    localStorage.removeItem(this.CLIENT_ID_KEY);
    localStorage.removeItem(this.CLIENT_ASSERTION_KEY);
    this._clientId.set(null);
    this._clientAssertion.set(null);
  }

  getClientId(): string | null {
    return this._clientId();
  }

  getClientAssertion(): string | null {
    return this._clientAssertion();
  }
}
