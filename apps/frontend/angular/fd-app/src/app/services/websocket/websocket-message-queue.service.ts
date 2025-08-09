import { Injectable } from '@angular/core';
import { first } from 'rxjs';
import { WebSocketService } from './websocket.service';

@Injectable({ providedIn: 'root' })
export class WebSocketMessageQueueService {
  private messageQueue: any[] = [];
  private isConnected = false;
  private isProcessing = false;

  constructor(private webSocketService: WebSocketService) {
    this.webSocketService.isConnected$.subscribe((connected: boolean) => {
      this.isConnected = connected;
      if (connected) {
        this.processMessageQueue();
      }
    });
  }

  sendMessage(message: any): void {
    if (this.isConnected) {
      this.webSocketService.postMessage(message);
    } else {
      this.messageQueue.push(message);
    }
  }

  private processMessageQueue(): void {
    if (this.isProcessing || !this.isConnected || this.messageQueue.length === 0) {
      return;
    }

    this.isProcessing = true;

    const message = this.messageQueue[0];
    this.webSocketService.postMessage(message);

    this.webSocketService.isConnected$.pipe(first()).subscribe((connected: boolean) => {
      if (connected) {
        this.messageQueue.shift();
      }
      this.isProcessing = false;
      this.processMessageQueue();
    });
  }
}
