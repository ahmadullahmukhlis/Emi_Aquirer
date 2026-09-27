import { ComponentFixture, TestBed } from '@angular/core/testing';

import { Datatable } from './datatable';

describe('Datatable', () => {
  let component: Datatable;
  let fixture: ComponentFixture<Datatable>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Datatable]
    })
    .compileComponents();

    fixture = TestBed.createComponent(Datatable);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
