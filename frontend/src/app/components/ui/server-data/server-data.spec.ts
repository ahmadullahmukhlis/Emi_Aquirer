import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ServerData } from './server-data';

describe('ServerData', () => {
  let component: ServerData;
  let fixture: ComponentFixture<ServerData>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ServerData]
    })
    .compileComponents();

    fixture = TestBed.createComponent(ServerData);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
