import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class ShareHelper {
  extractItems(res: any): any[] {
    if (Array.isArray(res)) return res;
    if (res?.data) return res.data;
    if (res?.content) return res.content;
    if (res?.items) return res.items;
    return [];
  }
}
