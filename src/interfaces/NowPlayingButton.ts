/**
 * A now playing item button displayed under the progress bar in now playing template.
 */
export interface NowPlayingButton {
    /**
     * Button ID
     */
    id: string;
    /**
     *
     * Type of system defined button - rate, repeat, add.
     */
    type: string;
    
    disabled?: boolean;
}
