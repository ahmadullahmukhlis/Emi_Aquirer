import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root',
})
export class JwtSignService {
  async signClientAssertion(
    clientId: string,
    audience: string,
    privateKeyPem: string,
    expiresInSeconds: number = 300,
  ): Promise<string> {
    const now = Math.floor(Date.now() / 1000);
    const header = { alg: 'RS256', typ: 'JWT' };
    const payload = {
      iss: clientId,
      sub: clientId,
      aud: audience,
      iat: now,
      exp: now + expiresInSeconds,
      jti: this.randomId(),
    };

    const encodedHeader = this.base64UrlEncode(JSON.stringify(header));
    const encodedPayload = this.base64UrlEncode(JSON.stringify(payload));
    const data = new TextEncoder().encode(`${encodedHeader}.${encodedPayload}`);

    const key = await this.importPrivateKey(privateKeyPem);
    const signature = await crypto.subtle.sign(
      { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
      key,
      data,
    );

    const encodedSignature = this.base64UrlEncode(signature);
    return `${encodedHeader}.${encodedPayload}.${encodedSignature}`;
  }

  private async importPrivateKey(pem: string): Promise<CryptoKey> {
    const clean = pem
      .replace('-----BEGIN PRIVATE KEY-----', '')
      .replace('-----END PRIVATE KEY-----', '')
      .replace(/\s+/g, '');
    const binary = Uint8Array.from(atob(clean), (c) => c.charCodeAt(0));
    return crypto.subtle.importKey(
      'pkcs8',
      binary.buffer,
      { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
      false,
      ['sign'],
    );
  }

  private base64UrlEncode(input: string | ArrayBuffer): string {
    let bytes: Uint8Array;
    if (typeof input === 'string') {
      bytes = new TextEncoder().encode(input);
    } else {
      bytes = new Uint8Array(input);
    }
    let base64 = btoa(String.fromCharCode(...bytes));
    base64 = base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
    return base64;
  }

  private randomId(): string {
    const bytes = new Uint8Array(16);
    crypto.getRandomValues(bytes);
    return Array.from(bytes)
      .map((b) => b.toString(16).padStart(2, '0'))
      .join('');
  }
}
