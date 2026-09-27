import { Component, inject, Input, OnInit } from '@angular/core';
import { IProportionalChart } from '../../../../models/chart.model';
import { NgApexchartsModule } from 'ng-apexcharts';
import { ApiService } from '../../../../services/api/api.service';

@Component({
  selector: 'app-pie-chart',
  standalone: true,
  imports: [NgApexchartsModule],
  templateUrl: './pie-chart.html',
  styleUrl: './pie-chart.css',
})
export class PieChart implements OnInit {
  @Input() config!: IProportionalChart;
  @Input() title: string = 'Distribution';
  @Input() isServer: boolean = false;
  @Input() url?: string;
  @Input() height: number = 350;

  loading = false;
  error: any = null;
  data: any[] = [];

  private api = inject(ApiService);

  ngOnInit() {
    if (this.isServer && this.url) {
      this.loadData();
    }
  }

  loadData() {
    if (!this.url) return;

    this.loading = true;
    this.error = null;

    this.api.get(this.url).subscribe({
      next: (res: any) => {
        this.data = Array.isArray(res) ? res : (res?.data ?? []);

        // Expected API format:
        // [
        //   { name: "Cash", value: 40 },
        //   { name: "Card", value: 60 }
        // ]

        this.config = {
          ...this.config,
          labels: this.data.map((x: any) => x.name),
          series: this.data.map((x: any) => x.value),
        };

        this.loading = false;
      },
      error: (err) => {
        this.error = err;
        this.loading = false;
      },
    });
  }
}
