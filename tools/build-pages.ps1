# Generates the SEO landing pages (areas, services, guide) and sitemap.xml
# from tools/pages.json. Output is plain static HTML committed to the repo,
# so Vercel still deploys with no build step.
#
# Run from anywhere:  powershell -ExecutionPolicy Bypass -File tools/build-pages.ps1

$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
$Base = 'https://www.thepet-stetician.com'
$Book = 'https://booking.moego.pet/ol/landing?name=ThePetStetician'
$BizId = "$Base/#business"
$Utf8 = New-Object System.Text.UTF8Encoding $false
$Today = Get-Date -Format 'yyyy-MM-dd'
$data = Get-Content (Join-Path $PSScriptRoot 'pages.json') -Raw -Encoding UTF8 | ConvertFrom-Json

$Paw = '&#128062;'; $Phone = '&#128222;'; $Bone = '&#129460;'

function Plain($html) { [System.Net.WebUtility]::HtmlDecode([regex]::Replace([string]$html, '<[^>]+>', '')) }
function ToJson($o) { ConvertTo-Json -InputObject $o -Depth 20 }

function ImgDims($file) {
  switch -Wildcard ($file) {
    'groom-*'           { return 800, 1066 }
    'dog-schnauzer.jpg' { return 265, 310 }
    'dog-doodle.jpg'    { return 260, 310 }
    'van-side.jpg'      { return 1150, 450 }
    'julia-portrait.jpg'{ return 700, 700 }
    'julia-beach.jpg'   { return 390, 400 }
  }
  throw "Unknown image size: $file"
}

$CountyByKey = @{}; foreach ($c in $data.counties) { $CountyByKey[$c.key] = $c }
$CityBySlug = @{};  foreach ($c in $data.cities)   { $CityBySlug[$c.slug] = $c }
$SvcBySlug = @{};   foreach ($s in $data.services) { $SvcBySlug[$s.slug] = $s }

$Sitemap = New-Object System.Collections.Generic.List[string]

# ---------- shared fragments ----------

$Header = @"
  <header class="site-header" id="top">
    <div class="stripe-bar" aria-hidden="true"></div>
    <nav class="nav container">
      <a href="/" class="brand">
        <span class="brand-main">THE PET-STETICIAN</span>
        <span class="brand-sub">Mobile Grooming</span>
      </a>
      <button class="nav-toggle" id="navToggle" aria-label="Open menu" aria-expanded="false">
        <span></span><span></span><span></span>
      </button>
      <ul class="nav-links" id="navLinks">
        <li><a href="/#services">Services</a></li>
        <li><a href="/#gallery">Gallery</a></li>
        <li><a href="/#about">About</a></li>
        <li><a href="/#testimonials">Reviews</a></li>
        <li><a href="/#area">Areas</a></li>
        <li><a href="/mobile-dog-grooming-guide">How It Works</a></li>
        <li><a href="$Book" target="_blank" rel="noopener" class="btn btn-pink btn-sm">Book Now</a></li>
      </ul>
    </nav>
  </header>
"@

$countyLinks = ($data.counties | ForEach-Object { "<li><a href=""/mobile-dog-grooming/$($_.slug)"">$($_.name)</a></li>" }) -join ''
$serviceLinks = ($data.services | ForEach-Object { "<li><a href=""/services/$($_.slug)"">$($_.name)</a></li>" }) -join ''

$Footer = @"
  <footer class="site-footer">
    <div class="stripe-bar" aria-hidden="true"></div>
    <div class="container footer-links">
      <div><h4>Areas We Serve</h4><ul>$countyLinks</ul></div>
      <div><h4>Services</h4><ul>$serviceLinks</ul></div>
      <div><h4>Learn More</h4><ul><li><a href="/mobile-dog-grooming-guide">How Mobile Grooming Works</a></li><li><a href="/#faq">FAQ</a></li><li><a href="/#about">Meet Julia</a></li></ul></div>
    </div>
    <div class="container footer-inner">
      <div class="footer-brand">
        <span class="brand-main">THE PET-STETICIAN</span>
        <span class="brand-sub">Mobile Grooming &middot; Pet Stylist</span>
      </div>
      <div class="footer-contact">
        <a href="$Book" target="_blank" rel="noopener">Book Online &rarr;</a>
        <a href="tel:+19738964547">973.896.4547</a>
        <a href="mailto:jfedorka1@gmail.com">jfedorka1@gmail.com</a>
        <a href="https://www.instagram.com/the_pet_stetician/" target="_blank" rel="noopener">@the_pet_stetician</a>
        <span>Palm Beach, Martin &amp; St. Lucie Counties, FL</span>
      </div>
    </div>
    <p class="copyright">&copy; <span id="year"></span> The Pet-Stetician &middot; Because they're family. They deserve the best. $Paw</p>
  </footer>

  <a href="tel:+19738964547" class="fab" aria-label="Call The Pet-Stetician">$Phone</a>
"@

function Crumbs($items) {
  $lis = for ($i = 0; $i -lt $items.Count; $i++) {
    $it = $items[$i]
    if ($i -lt $items.Count - 1) { "<li><a href=""$($it.url)"">$($it.name)</a></li>" }
    else { "<li aria-current=""page"">$($it.name)</li>" }
  }
  "<nav class=""breadcrumb"" aria-label=""Breadcrumb""><ol>$($lis -join '')</ol></nav>"
}

function CrumbLd($items, $pageUrl) {
  $list = for ($i = 0; $i -lt $items.Count; $i++) {
    $u = $items[$i].url; if ($u -eq '/') { $u = '' }
    [ordered]@{ '@type' = 'ListItem'; 'position' = $i + 1; 'name' = (Plain $items[$i].name); 'item' = "$Base$u" }
  }
  $list[-1].item = $pageUrl
  [ordered]@{ '@type' = 'BreadcrumbList'; '@id' = "$pageUrl#breadcrumb"; 'itemListElement' = @($list) }
}

function FaqHtml($faqs) {
  ($faqs | ForEach-Object { "        <details>`n          <summary>$($_.q)</summary>`n          <p>$($_.a)</p>`n        </details>" }) -join "`n"
}

function FaqLd($faqs, $pageUrl) {
  [ordered]@{
    '@type' = 'FAQPage'; '@id' = "$pageUrl#faq"
    'mainEntity' = @($faqs | ForEach-Object {
      [ordered]@{ '@type' = 'Question'; 'name' = (Plain $_.q); 'acceptedAnswer' = [ordered]@{ '@type' = 'Answer'; 'text' = (Plain $_.a) } }
    })
  }
}

function WebPageLd($pageUrl, $title, $desc) {
  [ordered]@{
    '@type' = 'WebPage'; '@id' = $pageUrl; 'url' = $pageUrl; 'name' = (Plain $title); 'description' = (Plain $desc)
    'isPartOf' = @{ '@id' = "$Base/#website" }; 'about' = @{ '@id' = $BizId }
    'breadcrumb' = @{ '@id' = "$pageUrl#breadcrumb" }; 'inLanguage' = 'en-US'
  }
}

function PageHero($crumbs, $eyebrow, $h1, $introParas, $img, $alt) {
  $w, $h = ImgDims $img
  $intro = ($introParas | ForEach-Object { "          <p class=""hero-text"">$_</p>" }) -join "`n"
@"
  <section class="page-hero">
    <div class="container">
      $(Crumbs $crumbs)
      <div class="page-hero-grid">
        <div>
          <p class="eyebrow">$Paw $eyebrow</p>
          <h1>$h1</h1>
$intro
          <div class="hero-cta">
            <a href="$Book" target="_blank" rel="noopener" class="btn btn-pink">$Paw Book Online</a>
            <a href="tel:+19738964547" class="btn btn-green">$Phone Call 973.896.4547</a>
          </div>
        </div>
        <figure class="arch page-hero-img">
          <img src="/img/$img" alt="$alt" width="$w" height="$h" fetchpriority="high" />
        </figure>
      </div>
    </div>
  </section>
"@
}

function ServiceCards($heading, $sub) {
  $cards = foreach ($s in $data.services) {
    "        <a class=""service-card"" href=""/services/$($s.slug)""><span class=""bone"">$Bone</span><h3>$($s.name)</h3><p>$($s.short)</p><span class=""card-link"">Learn more &rarr;</span></a>"
  }
  $cards += "        <article class=""service-card""><span class=""bone"">$Bone</span><h3>Nail Trimming</h3><p>Safe, careful trims to keep paws healthy and comfy.</p></article>"
  $cards += "        <article class=""service-card""><span class=""bone"">$Bone</span><h3>Ear Cleaning</h3><p>Gentle cleaning to help prevent buildup and infection.</p></article>"
@"
  <section class="section alt">
    <div class="container">
      <div class="section-head">
        <p class="kicker">What We Offer</p>
        <h2>$heading</h2>
        <p class="section-sub">$sub</p>
      </div>
      <div class="services-grid">
$($cards -join "`n")
      </div>
    </div>
  </section>
"@
}

function FaqSection($heading, $faqs) {
@"
  <section class="faq section" id="faq">
    <div class="container">
      <div class="section-head">
        <p class="kicker">Good to Know</p>
        <h2>$heading</h2>
      </div>
      <div class="faq-list">
$(FaqHtml $faqs)
      </div>
    </div>
  </section>
"@
}

$CtaBand = @"
  <section class="cta-band">
    <div class="container">
      <h2>Ready for a <span class="script">fresh look?</span></h2>
      <p>Book online in seconds, or call or text and we'll find a time that works for you.</p>
      <div class="hero-cta center">
        <a href="$Book" target="_blank" rel="noopener" class="btn btn-pink">$Paw Book Online</a>
        <a href="tel:+19738964547" class="btn btn-green">$Phone Call 973.896.4547</a>
      </div>
    </div>
  </section>
"@

function Chips($items) {
  $lis = foreach ($it in $items) {
    if ($it.url) { "<li><a href=""$($it.url)"">$($it.name)</a></li>" } else { "<li><span>$($it.name)</span></li>" }
  }
  "<ul class=""chip-list"">$($lis -join '')</ul>"
}

function Write-Page($path, $title, $desc, $img, $imgAlt, $graph, $main) {
  $url = "$Base$path"
  $ld = ToJson ([ordered]@{ '@context' = 'https://schema.org'; '@graph' = @($graph) })
  $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>$title</title>
  <meta name="description" content="$desc" />
  <meta name="robots" content="index, follow, max-image-preview:large" />
  <meta name="theme-color" content="#f4d7de" />
  <link rel="canonical" href="$url" />

  <meta property="og:site_name" content="The Pet-Stetician" />
  <meta property="og:locale" content="en_US" />
  <meta property="og:title" content="$title" />
  <meta property="og:description" content="$desc" />
  <meta property="og:type" content="website" />
  <meta property="og:url" content="$url" />
  <meta property="og:image" content="$Base/img/$img" />
  <meta property="og:image:alt" content="$imgAlt" />
  <meta name="twitter:card" content="summary_large_image" />

  <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>$Paw</text></svg>" />
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&family=Sacramento&display=swap" rel="stylesheet" />
  <link rel="stylesheet" href="/styles.css" />

  <!-- Generated by tools/build-pages.ps1 from tools/pages.json - edit those, not this file -->
  <script type="application/ld+json">
$ld
  </script>
</head>
<body>

$Header

  <main>
$main
  </main>

$Footer

  <script src="/script.js"></script>
</body>
</html>
"@
  $file = Join-Path $Root (($path.TrimStart('/') -replace '/', '\') + '.html')
  New-Item -ItemType Directory -Force (Split-Path $file -Parent) | Out-Null
  [IO.File]::WriteAllText($file, $html, $Utf8)
  $Sitemap.Add($url)
}

# ---------- city pages ----------

foreach ($c in $data.cities) {
  $county = $CountyByKey[$c.county]
  $path = "/mobile-dog-grooming/$($c.slug)"
  $url = "$Base$path"
  $title = "Mobile Dog Grooming in $($c.name), FL | The Pet-Stetician"
  $desc = "Stress-free mobile dog grooming in $($c.name), FL. Julia brings a fully equipped grooming van to your home for one-on-one baths, haircuts, de-shedding and more."
  $crumbs = @(
    @{ name = 'Home'; url = '/' },
    @{ name = $county.name; url = "/mobile-dog-grooming/$($county.slug)" },
    @{ name = $c.name; url = $path }
  )
  $faqs = @(
    $c.faq,
    [pscustomobject]@{ q = "How much does mobile dog grooming cost in $($c.name)?"; a = "Pricing depends on your dog&rsquo;s size, coat type, and the services you choose. Reach out for a quick, personalized quote." },
    [pscustomobject]@{ q = "How do I book a mobile groomer in $($c.name)?"; a = "The easiest way is to <a href='$Book' target='_blank' rel='noopener'>book online</a>. You can also call or text 973.896.4547, or send a message through the contact form on our homepage." }
  )
  $nearby = @($c.nearby | ForEach-Object { @{ name = $CityBySlug[$_].name; url = "/mobile-dog-grooming/$_" } })
  $nearby += @{ name = "All of $($county.name)"; url = "/mobile-dog-grooming/$($county.slug)" }

  $main = @"
$(PageHero $crumbs "Mobile Dog Grooming &middot; $($county.name)" "Mobile Dog Grooming in $($c.name), FL" @($c.intro) $c.img $c.imgAlt)

  <section class="section">
    <div class="container prose">
      <div class="quick-answer">
        <p class="kicker">Quick answer</p>
        <p>Yes. The Pet-Stetician offers mobile dog grooming in $($c.name), FL. Julia brings a fully equipped grooming van to your home and grooms your dog one-on-one, with no cages, no long waits, and no car rides. <a href="$Book" target="_blank" rel="noopener">Book online</a> or call or text 973.896.4547.</p>
      </div>
      <h2>$($c.h2)</h2>
$(($c.p | ForEach-Object { "      <p>$_</p>" }) -join "`n")
    </div>
  </section>

$(ServiceCards "Mobile Grooming Services in $($c.name)" "Every service comes to your driveway, tailored to your dog&rsquo;s coat and temperament.")

  <section class="section">
    <div class="container prose">
      <h2>Nearby areas we serve</h2>
      <p>We also groom throughout $($county.name) and beyond. Not sure if you&rsquo;re in range? Just ask.</p>
      $(Chips $nearby)
    </div>
  </section>

$(FaqSection "$($c.name) Mobile Grooming FAQ" $faqs)

$CtaBand
"@

  $graph = @(
    (WebPageLd $url $title $desc),
    (CrumbLd $crumbs $url),
    [ordered]@{
      '@type' = 'Service'; '@id' = "$url#service"
      'name' = "Mobile Dog Grooming in $($c.name), FL"; 'serviceType' = 'Mobile dog grooming'
      'provider' = @{ '@id' = $BizId }
      'areaServed' = [ordered]@{ '@type' = 'City'; 'name' = "$($c.name), FL"; 'containedInPlace' = [ordered]@{ '@type' = 'AdministrativeArea'; 'name' = "$($county.name), FL" } }
      'url' = $url
    },
    (FaqLd $faqs $url)
  )
  Write-Page $path $title $desc $c.img $c.imgAlt $graph $main
}

# ---------- county pages ----------

foreach ($k in $data.counties) {
  $path = "/mobile-dog-grooming/$($k.slug)"
  $url = "$Base$path"
  $title = "Mobile Dog Grooming in $($k.name), FL | The Pet-Stetician"
  $desc = "Stress-free mobile dog grooming across $($k.name), FL. One-on-one grooming in a fully equipped van at your home. See the cities we serve and book online."
  $crumbs = @(@{ name = 'Home'; url = '/' }, @{ name = $k.name; url = $path })
  $cityChips = @($k.cities | ForEach-Object { if ($_.slug) { @{ name = $_.name; url = "/mobile-dog-grooming/$($_.slug)" } } else { @{ name = $_.name; url = '' } } })
  $faqs = @(
    $k.faq[0],
    [pscustomobject]@{ q = "How does mobile grooming work in $($k.name)?"; a = "We come to you. Julia arrives in a fully equipped grooming van and grooms your pet one-on-one right outside your home, with no cages, no long waits, and no stressful car rides. <a href='/mobile-dog-grooming-guide'>See how it works</a>." },
    [pscustomobject]@{ q = "How much does mobile dog grooming cost in $($k.name)?"; a = "Pricing depends on your dog&rsquo;s size, coat type, and the services you choose. Reach out for a quick, personalized quote." },
    [pscustomobject]@{ q = 'How often should my dog be groomed?'; a = 'Most dogs do well with grooming every 4&ndash;8 weeks, depending on breed and coat. We&rsquo;re happy to recommend a schedule that keeps your pet looking and feeling their best.' }
  )
  $sections = ($k.sections | ForEach-Object { "      <h2>$($_.h2)</h2>`n" + (($_.p | ForEach-Object { "      <p>$_</p>" }) -join "`n") }) -join "`n"

  $main = @"
$(PageHero $crumbs 'Mobile Dog Grooming &middot; Treasure Coast &amp; Palm Beaches' "Mobile Dog Grooming in $($k.name), FL" @($k.intro) $k.img $k.imgAlt)

  <section class="section">
    <div class="container prose">
      <div class="quick-answer">
        <p class="kicker">Quick answer</p>
        <p>The Pet-Stetician is a mobile dog groomer serving all of $($k.name), FL. Julia brings a fully equipped grooming van to your home and grooms your dog one-on-one, with no cages, no long waits, and no car rides.</p>
      </div>
$sections
      <h2>Cities we serve in $($k.name)</h2>
      $(Chips $cityChips)
      <p>&hellip;and everywhere in between. Not sure if you&rsquo;re in our range? Call or text 973.896.4547.</p>
    </div>
  </section>

$(ServiceCards "Mobile Grooming Services in $($k.name)" 'Full-service grooming for all breeds, done gently and with care.')

$(FaqSection "$($k.name) Mobile Grooming FAQ" $faqs)

$CtaBand
"@

  $graph = @(
    (WebPageLd $url $title $desc),
    (CrumbLd $crumbs $url),
    [ordered]@{
      '@type' = 'Service'; '@id' = "$url#service"
      'name' = "Mobile Dog Grooming in $($k.name), FL"; 'serviceType' = 'Mobile dog grooming'
      'provider' = @{ '@id' = $BizId }
      'areaServed' = [ordered]@{ '@type' = 'AdministrativeArea'; 'name' = "$($k.name), FL" }
      'url' = $url
    },
    (FaqLd $faqs $url)
  )
  Write-Page $path $title $desc $k.img $k.imgAlt $graph $main
}

# ---------- service pages ----------

$areaChips = @($data.counties | ForEach-Object { @{ name = $_.name; url = "/mobile-dog-grooming/$($_.slug)" } })

foreach ($s in $data.services) {
  $path = "/services/$($s.slug)"
  $url = "$Base$path"
  $title = "$($s.h1) in South Florida | The Pet-Stetician"
  $desc = "$($s.short) $($s.h1) at your home in Palm Beach, Martin &amp; St. Lucie Counties, FL. One-on-one, no cages, no car rides."
  $crumbs = @(@{ name = 'Home'; url = '/' }, @{ name = 'Services'; url = '/#services' }, @{ name = $s.name; url = $path })
  $faqs = @($s.faq) + [pscustomobject]@{ q = "Where do you offer mobile $((Plain $s.name).ToLower())?"; a = 'Across Palm Beach, Martin, and St. Lucie Counties, Florida, including West Palm Beach, Jupiter, Wellington, Palm Beach Gardens, Stuart, Port St. Lucie, and everywhere in between.' }
  $sections = ($s.sections | ForEach-Object {
    $body = if ($_.ul) { "      <ul class=""paw-list"">" + (($_.ul | ForEach-Object { "<li>$_</li>" }) -join '') + '</ul>' } else { ($_.p | ForEach-Object { "      <p>$_</p>" }) -join "`n" }
    "      <h2>$($_.h2)</h2>`n$body"
  }) -join "`n"
  $related = ($s.related | ForEach-Object { $r = $SvcBySlug[$_]; "        <a class=""service-card"" href=""/services/$($r.slug)""><span class=""bone"">$Bone</span><h3>$($r.name)</h3><p>$($r.short)</p><span class=""card-link"">Learn more &rarr;</span></a>" }) -join "`n"

  $main = @"
$(PageHero $crumbs 'Mobile Grooming Service' $s.h1 @($s.short + ' Done one-on-one in our grooming van, right outside your home.') $s.img $s.imgAlt)

  <section class="section">
    <div class="container prose">
      <div class="quick-answer">
        <p class="kicker">Quick answer</p>
        <p>$($s.quick)</p>
      </div>
$sections
      <h2>Where we offer $((Plain $s.name).ToLower())</h2>
      <p>We bring $((Plain $s.name).ToLower()) to homes across all three counties we serve:</p>
      $(Chips $areaChips)
    </div>
  </section>

  <section class="section alt">
    <div class="container">
      <div class="section-head"><p class="kicker">More Services</p><h2>You might also like</h2></div>
      <div class="services-grid">
$related
      </div>
    </div>
  </section>

$(FaqSection "$($s.name) FAQ" $faqs)

$CtaBand
"@

  $graph = @(
    (WebPageLd $url $title $desc),
    (CrumbLd $crumbs $url),
    [ordered]@{
      '@type' = 'Service'; '@id' = "$url#service"
      'name' = (Plain $s.h1); 'serviceType' = (Plain $s.name); 'description' = (Plain $s.short)
      'provider' = @{ '@id' = $BizId }
      'areaServed' = @($data.counties | ForEach-Object { [ordered]@{ '@type' = 'AdministrativeArea'; 'name' = "$($_.name), FL" } })
      'url' = $url
    },
    (FaqLd $faqs $url)
  )
  Write-Page $path $title $desc $s.img $s.imgAlt $graph $main
}

# ---------- guide ----------

$g = $data.guide
$path = "/$($g.slug)"
$url = "$Base$path"
$crumbs = @(@{ name = 'Home'; url = '/' }, @{ name = 'How Mobile Grooming Works'; url = $path })
$steps = ($g.steps | ForEach-Object { "<li>$_</li>" }) -join ''
$rows = ($g.compare | ForEach-Object { "<tr><th scope=""row"">$($_[0])</th><td>$($_[1])</td><td>$($_[2])</td></tr>" }) -join ''
$prep = ($g.prep | ForEach-Object { "<li>$_</li>" }) -join ''

$main = @"
$(PageHero $crumbs 'Mobile Grooming 101' $g.h1 @('Everything you need to know about getting your dog groomed at home, from booking to the final brush-out.') 'van-side.jpg' 'The Pet-Stetician mobile dog grooming van')

  <section class="section">
    <div class="container prose">
      <div class="quick-answer">
        <p class="kicker">Quick answer</p>
        <p>$($g.quick)</p>
      </div>

      <h2>How a mobile grooming appointment works</h2>
      <ol class="steps">$steps</ol>

      <h2>Mobile grooming vs. a grooming salon</h2>
      <div class="table-wrap">
        <table class="compare-table">
          <thead><tr><th scope="col"></th><th scope="col">Mobile grooming</th><th scope="col">Typical salon</th></tr></thead>
          <tbody>$rows</tbody>
        </table>
      </div>

      <h2>How to get ready for your appointment</h2>
      <ul class="paw-list">$prep</ul>

      <h2>What affects the price?</h2>
      <p>Pricing depends on your dog&rsquo;s size, coat type, and the services you choose, such as a <a href="/services/bath-and-brush">bath &amp; brush</a>, <a href="/services/haircuts-and-styling">haircut &amp; styling</a>, or <a href="/services/de-shedding">de-shedding</a>. Reach out for a quick, personalized quote.</p>

      <h2>How often should my dog be groomed?</h2>
      <p>Most dogs do well with grooming every 4&ndash;8 weeks, depending on breed and coat. Curly and doodle coats usually need the shorter end of that range; short coats can often go longer. Starting a <a href="/services/puppy-grooming">puppy</a> early makes every future groom easier.</p>

      <h2>Where we groom</h2>
      <p>The Pet-Stetician serves Palm Beach, Martin, and St. Lucie Counties in Florida.</p>
      $(Chips $areaChips)
    </div>
  </section>

$(FaqSection 'Mobile Grooming FAQ' $g.faq)

$CtaBand
"@

$graph = @(
  (WebPageLd $url $g.title $g.description),
  (CrumbLd $crumbs $url),
  [ordered]@{
    '@type' = 'Article'; '@id' = "$url#article"; 'headline' = (Plain $g.h1); 'description' = (Plain $g.description)
    'image' = "$Base/img/van-side.jpg"; 'author' = @{ '@id' = $BizId }; 'publisher' = @{ '@id' = $BizId }
    'mainEntityOfPage' = @{ '@id' = $url }; 'dateModified' = $Today; 'inLanguage' = 'en-US'
  },
  (FaqLd $g.faq $url)
)
Write-Page $path $g.title $g.description 'van-side.jpg' 'The Pet-Stetician mobile dog grooming van' $graph $main

# ---------- sitemap ----------

$homeImgs = 'van-side.jpg','julia-portrait.jpg','julia-beach.jpg','groom-flamingo-doodle.jpg','groom-golden.jpg','groom-merle-doodle.jpg','groom-bichon-daisy.jpg','groom-choc-lab.jpg','groom-shihtzu.jpg','groom-chihuahua.jpg','groom-beach-pup.jpg'
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('<?xml version="1.0" encoding="UTF-8"?>')
[void]$sb.AppendLine('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"')
[void]$sb.AppendLine('        xmlns:image="http://www.google.com/schemas/sitemap-image/1.1">')
[void]$sb.AppendLine("  <url>`n    <loc>$Base/</loc>`n    <lastmod>$Today</lastmod>`n    <priority>1.0</priority>")
foreach ($i in $homeImgs) { [void]$sb.AppendLine("    <image:image><image:loc>$Base/img/$i</image:loc></image:image>") }
[void]$sb.AppendLine('  </url>')
foreach ($u in $Sitemap) { [void]$sb.AppendLine("  <url>`n    <loc>$u</loc>`n    <lastmod>$Today</lastmod>`n  </url>") }
[void]$sb.AppendLine('</urlset>')
[IO.File]::WriteAllText((Join-Path $Root 'sitemap.xml'), $sb.ToString(), $Utf8)

Write-Host "Built $($Sitemap.Count) pages + sitemap.xml"
