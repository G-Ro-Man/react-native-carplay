import { NowPlayingButton } from '../interfaces/NowPlayingButton';
import { BaseEvent, Template, TemplateConfig } from './Template';
interface ButtonPressedEvent extends BaseEvent {
    /**
     * Button ID
     */
    id: string;
    /**
     * Button Index
     */
    index: number;
    /**
     * template ID
     */
    templateId: string;
    /**
     * Action type, rate, add, repeat
     */
    action: string;
}
export interface NowPlayingConfig extends TemplateConfig {
    /**
     * The title displayed in the navigation bar while the list template is visible.
     */
    title?: string;
    /**
     * The array of now playing buttons displayed on the template.
     */
    buttons: NowPlayingButton[];
    /**
     * Fired when a button is pressed
     */
    onButtonPressed?(e: ButtonPressedEvent): void;

    albumArtistButton?: boolean;

    upNextButton?: boolean;
}
export class NowPlayingTemplate extends Template<NowPlayingConfig> {
  public get type(): string {
    return 'nowplaying';
  }

  get eventMap() {
    return {
      nowPlayingButtonPressed: 'onButtonPressed',
    }
  }
}
