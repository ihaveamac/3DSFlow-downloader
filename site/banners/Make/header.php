<?php
// this is @Gocario's work, licensed under the MIT license
// see `LICENSE.md` at project root for details
?>
<div>
    <canvas id="canvasPreview" width="400px" height="222px">No canvas? That's sad...</canvas>
    <p>Please, right click on the preview to download it.</p>
</div>
<div>
    <div>
        <select id="templateType" name="templateType">
            <option value selected disabled>Select a cover!</option>
            <optgroup label="Nintendo 3DS Games">
                <option value="template-basic-banner-fullscreen.png">Generic</option>
                <option value="template-new-banner-fullscreen.png" data-offset-x="10" data-offset-y="10" disabled>Generic New (Not available yet)</option>
                <option value="template-nnetwork-banner-fullscreen.png">Nintendo Network</option>
                <option value="template-amiibo-banner-fullscreen.png">amiibo</option>
                <option value="template-eshop-banner-fullscreen.png">Nintendo eShop</option>
            </optgroup>
            <optgroup label="Virtual Console">
                <option value="template-VC-generic-banner-fullscreen.png">Generic/Other</option>
                <option value="template-VC-GB-banner-fullscreen.png">Game Boy</option>
                <option value="template-VC-GBC-banner-fullscreen.png">Game Boy Color</option>
                <option value="template-VC-GBA-banner-fullscreen.png">Game Boy Advance</option>
                <option value="template-VC-NES-banner-fullscreen.png">Nintendo Entertainment System</option>
                <option value="template-VC-SNES-banner-fullscreen.png">Super NES</option>
                <option value="template-VC-GG-banner-fullscreen.png">Game Gear</option>
            </optgroup>
            <optgroup label="Other">
                <option value="template-system-banner-fullscreen.png">System</option>
                <option value="template-hb-banner-fullscreen.png">Homebrew</option>
            </optgroup>
        </select>
        <input type="button" id="coverGame" name="coverGame" value="Load a cover">
        <input type="button" id="importCoverGame" name="importCoverGame" value="Import a cover">
        <!-- TODO: The template selector of the import because of the data-offset- -->
    </div>
    <div>
        <label><input type="checkbox" id="demoCheck" name="demoCheck">&nbsp;Add the demo logo</label>
    </div>
    <div class="hidden">
        <!-- To load images -->
        <img id="templatePreview" alt="templatePreview">
        <img id="coverPreview" alt="coverPreview">
        <img id="demoPreview" alt="demoPreview">
        <img id="importCoverPreview" alt="importCoverPreview">
        <form id="fileForm">
            <input type="file" id="fileLoad">
        </form>
    </div>
</div>

<script type="text/javascript">
    /* this is @Gocario's work, licensed under the MIT license
       see https://github.com/ihaveamac/3DSFlow-downloader/blob/master/LICENSE.md for details */
    function el(e){return document.getElementById(e);}
    function addEvent(e,ev,f){if(e.addEventListener){e.addEventListener(ev,f,false);return true;}else if(e.attachEvent)e.attachEvent('on'+ev,f);}

    addEvent(window, 'load', function() {
        var $canvas = el('canvasPreview');
        var ctx = $canvas.getContext("2d");

        /** Hidden previews **/
        var $templatePreview = el('templatePreview');
        var $coverPreview = el('coverPreview');
        var $importCoverPreview = el('importCoverPreview');
        var $demoPreview = el('demoPreview');
        var COVER_DEFAULT_X = 94, COVER_DEFAULT_Y = 9, COVER_SIZE = 186;
        var coverX = COVER_DEFAULT_X, coverY = COVER_DEFAULT_Y;
        var demoX = COVER_DEFAULT_X, demoY = COVER_DEFAULT_Y;
        var importCover = false;
        var updatePreview = function() {
            ctx.clearRect(0, 0, $canvas.width, $canvas.height);
            ctx.drawImage($templatePreview, 0, 0);
            if (importCover) ctx.drawImage($importCoverPreview, coverX, coverY, COVER_SIZE, COVER_SIZE, COVER_DEFAULT_X, COVER_DEFAULT_Y, COVER_SIZE, COVER_SIZE);
            else ctx.drawImage($coverPreview, coverX, coverY, COVER_SIZE, COVER_SIZE);
            if ($demoCheck.checked)ctx.drawImage($demoPreview, demoX, demoY);
        };
        addEvent($templatePreview, 'load', updatePreview);
        addEvent($coverPreview, 'load', updatePreview);
        addEvent($importCoverPreview, 'load', updatePreview);
        addEvent($demoPreview, 'load', updatePreview);
        /*********************/

        /** Select changes (Template) **/
        var $templateType = el('templateType');
        var templateFolder = "banners/Templates/"; //"//ianburgwin.net/3dsflow/banners/Templates/";
        var updateTemplatePreview = function() {
            $templatePreview.src = templateFolder + $templateType.value;
            coverX = (parseInt($templateType.selectedOptions[0].dataset.offsetX) || COVER_DEFAULT_X);
            coverY = (parseInt($templateType.selectedOptions[0].dataset.offsetY) || COVER_DEFAULT_Y);
        };
        addEvent($templateType, 'change', updateTemplatePreview);
        // updateTemplatePreview();
        /*******************************/

        /** File changes (Cover) **/
        var $coverGame = el('coverGame');
        var $importCoverGame = el('importCoverGame');
        addEvent($coverGame, 'click', function() {
            importCover = false;
            el('fileLoad').click();
        });
        addEvent($importCoverGame, 'click', function() {
            importCover = true;
            el('fileLoad').click();
        });
        addEvent(el('fileLoad'), 'change', function() {
            tempImageReader.readAsDataURL(this.files[0]);
            el('fileForm').reset();
        });
        var tempImageReader = new FileReader();
        addEvent(tempImageReader, 'load', function() {
            if (importCover) $importCoverPreview.src = tempImageReader.result;
            else $coverPreview.src = tempImageReader.result;
        });
        /**************************/

        /** Demo **/
        var $demoCheck = el('demoCheck');
        $demoPreview.src = templateFolder + "!template-demo-logo.png";
        addEvent($demoCheck, 'change', updatePreview);
        /**********/
    });
</script>
