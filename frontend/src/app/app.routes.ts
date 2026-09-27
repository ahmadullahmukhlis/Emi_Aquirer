import { Routes } from '@angular/router';
import { AuthGuard } from './guards/auth.guard';
import { Login } from './pages/login/login';
import { MainContent } from './components/layout/main-content/main-content';
import { GatewayLayout } from './components/layout/gateway-layout/gateway-layout';

const gatewayViews: Record<string, string[]> = {
  acquiring: ['merchants', 'terminals'],
  transactions: ['monitor', 'details', 'recovery'],
  settlements: ['batches', 'reconciliation', 'exceptions'],
  operations: ['audit'],
  iso: ['profiles'],
};

export const routes: Routes = [
  { path: 'login', component: Login },

  {
    path: '',
    component: MainContent, 
    canActivate: [AuthGuard],
    children: [
      { path: '', pathMatch: 'full', redirectTo: 'gateway/transactions' },
      {
        path: 'auth/users',
        loadComponent: () => import('./pages/auth/users/users').then(m => m.AuthUsers)
      },
      {
        path: 'auth/roles',
        loadComponent: () => import('./pages/auth/roles/roles').then(m => m.Roles)
      },
      {
        path: 'auth/permissions',
        loadComponent: () => import('./pages/auth/permissions/permissions').then(m => m.Permissions)
      },
      {
        path: 'auth/mfa',
        loadComponent: () => import('./pages/auth/mfa/mfa').then(m => m.MfaPage)
      },
      {
        path: 'gateway',
        component: GatewayLayout,
        children: [
          { path: '', pathMatch: 'full', redirectTo: 'transactions' },
          ...Object.entries(gatewayViews).flatMap(([section, views]) => [
            {
              path: section,
              loadComponent: () => import('./pages/gateway/gateway-section').then(m => m.GatewaySection),
              data: { section },
            },
            ...views.map(view => ({
              path: `${section}/${view}`,
              loadComponent: () => import('./pages/gateway/gateway-section').then(m => m.GatewaySection),
              data: { section, view },
            })),
          ]),
        ],
      },
    ]
  },

  { path: '**', redirectTo: '' }
];
