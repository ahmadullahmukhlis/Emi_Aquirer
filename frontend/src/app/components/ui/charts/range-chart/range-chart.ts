import { Component, inject, Input, OnInit } from '@angular/core';
import { IRangeChart } from '../../../../models/chart.model';
import { NgApexchartsModule } from 'ng-apexcharts';
import { ApiService } from '../../../../services/api/api.service';

@Component({
  selector: 'app-range-chart',
  standalone: true,
  imports: [NgApexchartsModule],
  templateUrl: './range-chart.html',
  styleUrl: './range-chart.css',
})
export class RangeChart implements OnInit {
  @Input() config!: IRangeChart;
  @Input() title: string = 'Range Analysis';
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

        /**
         * Expected API format (recommended):
         *
         * [
         *   { name: "Jan", min: 10, max: 20 },
         *   { name: "Feb", min: 15, max: 25 }
         * ]
         */

        const normalizedData = this.data.map((item: any) => ({
          x: item.name,
          y: [Number(item.min), Number(item.max)],
        }));

        this.config = {
          ...this.config,
          series: [
            {
              name: this.title,
              data: normalizedData,
            },
          ],
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
