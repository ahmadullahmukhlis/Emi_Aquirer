import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';

export interface User {
  username: string;
  email: string;
  image?: string; // optional profile picture
}

export interface AppState {
  user: User | null;
}

@Injectable({
  providedIn: 'root' // ✅ singleton global state
})
export class AppStateService {

  // private state object
  private state: AppState = { user: null };

  // BehaviorSubject to emit state changes
  private stateSubject = new BehaviorSubject<AppState>(this.state);

  // Observable to subscribe globally
  public state$: Observable<AppState> = this.stateSubject.asObservable();

  constructor() {
    // load state from localStorage if exists
    const saved = localStorage.getItem('appState');
    if (saved) {
      this.state = JSON.parse(saved);
      this.stateSubject.next(this.state);
    }
  }

  // ---- Setters ----

  setUser(user: User) {
    this.state.user = user;
    this.emit();
  }

  clearUser() {
    this.state.user = null;
    this.emit();
  }

  // ---- Getters ----

  get user(): User | null {
    return this.state.user;
  }

  // emit updated state
  private emit() {
    this.stateSubject.next({ ...this.state });
    localStorage.setItem('appState', JSON.stringify(this.state));
  }
}
