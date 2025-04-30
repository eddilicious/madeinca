var maxImageCount = 40; // Set max image count
var imageSpeed = 4; // Set the image animation speed
var startFloatingImages; // Call to start floating images animation
var stopFloatingImages; // Call to stop adding floating images
var toggleFloatingImages; // Call to start or stop the floating images animation depending on whether it's already running
var removeFloatingImages; // Call to stop the floating images animation and remove all images immediately


var imageUrls = ["../images/leaf1.png", "../images/leaf2.png", "../images/leaf3.png", "../images/leaf4.png", "../images/leaf5.png", "../images/leaf6.png"]; // Add your image URLs here
var okGifs = ["../gifs/nice1.gif", "../gifs/nice2.gif"]; // Add your image URLs here
var okMp3s = ["../mp3/i.am.canadian.mp3", "../mp3/excited_01.mp3", "../mp3/excited_02.mp3", "../mp3/excited_03.mp3", "../mp3/excited_04.mp3", "../mp3/excited_05.mp3", "../mp3/excited_06.mp3", "../mp3/excited_07.mp3", "../mp3/excited_08.mp3", "../mp3/o.canada.mp3"]; // Add your image URLs here
var meanGifs = ["../gifs/mean1.gif", "../gifs/mean2.gif", "../gifs/mean3.gif", "../gifs/mean4.gif"]; // Add your image URLs here
var meanMp3s = ["../mp3/no_01.mp3", "../mp3/no_02.mp3", "../mp3/no_04.mp3", "../mp3/no_05.mp3", "../mp3/no_08.mp3", "../mp3/no_rat.mp3"]; // Add your image URLs here
var idkGifs = ["../gifs/idk1.gif"]; // Add your image URLs here
var idkMp3s = ["../mp3/no_f_02.mp3", "../mp3/no_f_03.mp3", "../mp3/no_f_04.mp3"]; // Add your image URLs here
var floatingImages = [];
var animateDiv;
var attribs = [];
var animationTimer = null;
var streamingImages = false;

function startIDK() {
    var img = document.createElement("img");
    var pick =  Math.random() * idkGifs.length | 0;
    img.src = idkGifs[pick];
    img.style.width = "400px"; // Set the image width
    img.style.height = "auto"; // Maintain aspect ratio

    var div = document.createElement("div");
    div.style.position = "fixed";
    div.style.zIndex = 100;
    div.style.width = "400px"; // Set the image width
    div.style.height = "400px"; // Maintain aspect ratio
    div.style.pointerEvents = "none"; // Ensure the image does not interfere with other elements
    //div.classList.add("floatingDiv");
    div.appendChild(img);

    div.style.bottom = "20px"; // Align to bottom
    div.style.left = "20px"; // Align to left
    
    document.body.appendChild(div);

    pick =  Math.random() * idkMp3s.length | 0;
    var music = idkMp3s[pick];

    var audio = document.createElement("audio");
    audio.src = music;
    audio.autoplay = true; // Auto play
    
    // Append to the body (or any container)
    document.body.appendChild(audio);
    
    // Handle when the music ends
    setTimeout(function () {
        div.remove(); // Remove the audio element if needed
        //streamingImages = false;
    }, 4000);

}

function startMean() {
    var img = document.createElement("img");
    var pick =  Math.random() * meanGifs.length | 0;
    img.src = meanGifs[pick];
    img.style.width = "400px"; // Set the image width
    img.style.height = "auto"; // Maintain aspect ratio

    var div = document.createElement("div");
    div.style.position = "fixed";
    div.style.zIndex = 100;
    div.style.width = "400px"; // Set the image width
    div.style.height = "400px"; // Maintain aspect ratio
    div.style.pointerEvents = "none"; // Ensure the image does not interfere with other elements
    //div.classList.add("floatingDiv");
    div.appendChild(img);

    div.style.bottom = "20px"; // Align to bottom
    div.style.left = "20px"; // Align to left
    
    document.body.appendChild(div);

    pick =  Math.random() * meanMp3s.length | 0;
    var music = meanMp3s[pick];

    var audio = document.createElement("audio");
    audio.src = music;
    audio.autoplay = true; // Auto play
    
    // Append to the body (or any container)
    document.body.appendChild(audio);
    
    // Handle when the music ends
    setTimeout(function () {
        div.remove(); // Remove the audio element if needed
        //streamingImages = false;
    }, 4000);

}



function startAnimate() {
    var img = document.createElement("img");
    var pick =  Math.random() * okGifs.length | 0;
    img.src = okGifs[pick];
    img.style.width = "400px"; // Set the image width
    img.style.height = "auto"; // Maintain aspect ratio

    var div = document.createElement("div");
    div.style.position = "fixed";
    div.style.zIndex = 100;
    div.style.width = "400px"; // Set the image width
    div.style.height = "400px"; // Maintain aspect ratio
    div.style.pointerEvents = "none"; // Ensure the image does not interfere with other elements
    //div.classList.add("floatingDiv");
    div.appendChild(img);

    div.style.bottom = "20px"; // Align to bottom
    div.style.left = "20px"; // Align to left
    
    document.body.appendChild(div);

    pick =  Math.random() * okMp3s.length | 0;
    var music = okMp3s[pick];

    var audio = document.createElement("audio");
    audio.src = music;
    audio.autoplay = true; // Auto play
    
    // Append to the body (or any container)
    document.body.appendChild(audio);
    
    // Handle when the music ends
    //audio.onended = function () {
        //div.remove(); // Remove the audio element if needed
        //streamingImages = false;
    //};
    setTimeout(function () {
        div.remove(); // Remove the audio element if needed
        //streamingImages = false;
    }, 8000);


}

function resetImage(div, a) {
    var width = window.innerWidth;
    var height = window.innerHeight;
    if (!div.children[0]) {
        return; // Exit the function
    }
    
    let img = div.children[0];       
    img.src = imageUrls[(Math.random() * imageUrls.length) | 0];
    img.style.width = "80px"; // Set the image width
    img.style.height = "auto"; // Maintain aspect ratio
    a.tiltAngle = Math.random() * 180 - 90;
    a.tiltAngleIncrement = Math.random() - 0.5;
    a.waveAngle = Math.random() - 0.5;
    img.style.transform = "rotate(" +  a.tiltAngle + "deg)"; 
    img.style.transform = "skew(${Math.random() * 10 - 10}deg, ${Math.random() * 5 - 5}deg)";

    div.style.left = Math.random() * width * 0.8 + 'px';
    div.style.top = Math.random() * height - height/2 + 'px';
    //document.body.innerHTML += "<span>(" + width + "," + height + ")</span><br";
    return div;
}

function startConfetti() {
    startAnimate();

    var width = window.innerWidth;
    var height = window.innerHeight;
    while (floatingImages.length < maxImageCount) {
        var img = document.createElement("img");
        var div = document.createElement("div");
        div.style.position = "absolute";
        div.style.zIndex = 10;
        div.style.width = "40px"; // Set the image width
        div.style.height = "auto"; // Maintain aspect ratio
        div.style.pointerEvents = "none"; // Ensure the image does not interfere with other elements
        //div.classList.add("floatingDiv");
        div.appendChild(img);
        a = {}
        attribs.push(a);

        document.body.appendChild(div);
        floatingImages.push(resetImage(div, a));
    }
    streamingImages = true;
    if (animationTimer === null) {
        (function runAnimation() {
            if (floatingImages.length === 0)
                animationTimer = null;
            else {
                updateImages();
                animationTimer = requestAnimationFrame(runAnimation);
            }
        })();
    }

    setTimeout(() => {removeConfetti();}, 10000); // Stop animation after 10 seconds
}

function stopConfetti() {
    streamingImages = false;
}

function removeConfetti() {
    stopConfetti();
    floatingImages.forEach(function(img) {
        document.body.removeChild(img);
    });
    floatingImages = [];
}

function toggleConfetti() {
    if (streamingImages)
        stopFloatingImages();
    else
        startFloatingImages();
}

function updateImages() {
    var width = window.innerWidth;
    var height = window.innerHeight;
    for (var i = 0; i < floatingImages.length; i++) {
        var div = floatingImages[i];
        var a = attribs[i];
        a.waveAngle += 0.01;
        if (!streamingImages && parseFloat(div.style.top) < -15)
            div.style.top = height + 100 + 'px';
        else {
            div.style.left = parseFloat(div.style.left) + Math.sin(a.waveAngle+i/100) + 'px';
            div.style.top = parseFloat(div.style.top) + (Math.cos(a.waveAngle+i/10) + imageSpeed) * 0.5 + 'px';
            if (div.children[0]) {
                img = div.children[0];
                a.tiltAngle = a.tiltAngle + a.tiltAngleIncrement;
                img.style.transform = "rotate(" +  Math.floor(a.tiltAngle) + "deg)"; 
            }
            
        }
        if (parseFloat(div.style.left) > width - 80 || parseFloat(div.style.left) < 0 || parseFloat(div.style.top) > height-80) {
            if (streamingImages && floatingImages.length <= maxImageCount)
                resetImage(div, a);
            else {
                document.body.removeChild(div);
                floatingImages.splice(i, 1);
                i--;
            }
        }
    }
}
