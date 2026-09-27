import { ComponentFixture, TestBed } from '@angular/core/testing';

import { DeleteConfirmation } from './delete-confirmation';

describe('DeleteConfirmation', () => {
  let component: DeleteConfirmation;
  let fixture: ComponentFixture<DeleteConfirmation>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [DeleteConfirmation]
    })
    .compileComponents();

    fixture = TestBed.createComponent(DeleteConfirmation);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
