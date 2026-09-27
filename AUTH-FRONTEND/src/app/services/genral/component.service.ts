import { inject, Injectable } from '@angular/core';
import { ApiService } from '../api/api.service';
import { map, Observable, Subject } from 'rxjs';
import { ShareHelper } from '../../helpers/SHare-helper';
import { HttpParams } from '@angular/common/http';
import { ToastService } from './tost.service';

@Injectable({ providedIn: 'root' })
export class ComponentService {
  private api = inject(ApiService);
  private sharehelper = inject(ShareHelper);
  private toastService = inject(ToastService);

  getList<T>(url: string): Observable<T[]> {
    return this.api.get(url).pipe(map((res: any) => this.sharehelper.extractItems(res)));
  }
  request(method: string, url: string, data: any) {
    return this.api.request(method, url, data);
  }
  private revalidateSubject = new Subject<string | null>();
  revalidate$ = this.revalidateSubject.asObservable();

  revalidate(id: string | null) {
    this.revalidateSubject.next(id);
  }
  load(url: string, state: any): Observable<any> {
    const queryParts: string[] = [];

    // Always include pagination
    queryParts.push(`page=${state.page ?? 1}`);
    queryParts.push(`pageSize=${state.pageSize ?? 10}`);

    if (state.sortBy) queryParts.push(`sortBy=${state.sortBy}`);
    if (state.sortDir) queryParts.push(`sortDir=${state.sortDir}`);

    if (state.filters && typeof state.filters === 'object') {
      Object.keys(state.filters).forEach((key) => {
        const value = state.filters[key];

        // Ignore null / undefined / objects
        if (value === null || value === undefined || typeof value === 'object') {
          return;
        }

        queryParts.push(`${key}=${value}`);
      });
    }

    const finalUrl = `${url}?${queryParts.join('&')}`;

    console.log('Final URL:', finalUrl);

    return this.api.get(finalUrl);
  }

  delete<T>(
    url: string,
    handlers: {
      onSuccess: (res: T) => void;
      onError: (err: any) => void;
    }
  ) {
    this.api.delete<T>(url).subscribe({
      next: (res) => {
        this.toastService.success('Deleted', 'Item deleted successfully');
        handlers.onSuccess(res);
      },
      error: (err) => {
        const message = err?.message ?? err;
        this.toastService.deleteError(message);
        handlers.onError(err);
      },
    });
  }
}
