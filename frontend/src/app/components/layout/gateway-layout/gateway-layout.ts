import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-gateway-layout',
  standalone: true,
  imports: [RouterOutlet],
  templateUrl: './gateway-layout.html',
  styleUrl: './gateway-layout.css',
})
export class GatewayLayout {}
