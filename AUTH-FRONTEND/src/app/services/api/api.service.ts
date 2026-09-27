import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpEvent, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root',
})
export class ApiService {
  private http = inject(HttpClient);
  private BASE_URL = this.stripTrailingSlash(import.meta.env.NG_APP_API_URL);

  private getHeaders(isFormData: boolean = false) {
    const token = localStorage.getItem('accessToken');
    const clientId = localStorage.getItem('clientId');
    const clientAssertion = localStorage.getItem('clientAssertion');
    let headers = new HttpHeaders({
      Authorization: token ? `Bearer ${token}` : '',
    });

    if (clientId) headers = headers.set('X-Client-Id', clientId);
    if (clientAssertion) headers = headers.set('X-Client-Assertion', clientAssertion);

    // Only add JSON content type if it's NOT FormData
    if (!isFormData) {
      headers = headers.set('Content-Type', 'application/json');
    }

    return headers;
  }
  // Check if string starts with "/"
  private startsWithSlash(value: string): String {
    const isBool = value.startsWith('/');
    if (isBool) {
      return value;
    }
    return '/' + value;
  }
  private stripTrailingSlash(value: string): string {
    return value.endsWith('/') ? value.slice(0, -1) : value;
  }

  get<T>(url: string, params: Record<string, any> = {}): Observable<T> {
    return this.http.get<T>(`${this.BASE_URL}${this.startsWithSlash(url)}`, {
      headers: this.getHeaders(),
      params: params,
    });
  }

  post<T>(url: string, body: any): Observable<T> {
    return this.http.post<T>(`${this.BASE_URL}${this.startsWithSlash(url)}`, body, {
      headers: this.getHeaders(),
    });
  }

  put<T>(url: string, body: any): Observable<T> {
    return this.http.put<T>(`${this.BASE_URL}${this.startsWithSlash(url)}`, body, {
      headers: this.getHeaders(),
    });
  }

  delete<T>(url: string): Observable<T> {
    return this.http.delete<T>(`${this.BASE_URL}${this.startsWithSlash(url)}`, {
      headers: this.getHeaders(),
    });
  }
  request<T>(method: string, url: string, body: any): Observable<HttpEvent<T>> {
    const isFormData = body instanceof FormData;

    return this.http.request<T>(method, `${this.BASE_URL}${this.startsWithSlash(url)}`, {
      body: body,
      headers: this.getHeaders(isFormData),
      observe: 'events', // Required for progress bars
      reportProgress: true, // Required for progress bars
    });
  }
}
