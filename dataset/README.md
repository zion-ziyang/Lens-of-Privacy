<h1>Dataset</h1>

<h3>Subset A</h3>
<ul style="list-style-type: none; padding-left: 0; text-align: left; margin-bottom: 20px;">
  <li><b>Include:</b> 344 conversations (April to December 2024)</li>
  <li><b>Source:</b>
    <ol style="text-align: left; padding-left: 20px;">
      <li>Media review articles (137)</li>
      <li>Video platforms (115)</li>
      <li>Social media platforms (92)</li>
    </ol>
  </li>
</ul>

> For ethical considerations, Subset A was used only to observe user interaction patterns during the study. Therefore, we only provide links to the data sources.

<p align="left" style="margin-top: 20px; margin-bottom: 20px;">
  Below is a preview of the data sources for Subset A. For the complete list, please see the <a href="Subset-A.csv"><code>Subset-A.csv</code></a> file.
</p>
<table align="center" style="margin-top: 20px; margin-bottom: 20px;">
  <thead>
    <tr>
      <th>Type</th>
      <th>Link</th>
      <th>Count</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Bilibili</td>
      <td><a href="https://www.bilibili.com/video/BV1j6z6YjEzp">https://www.bilibili.com/video/...</a></td>
      <td>8</td>
    </tr>
    <tr>
      <td>...</td>
      <td></td>
      <td></td>
    </tr>
    <tr>
      <td>Youtube</td>
      <td><a href="https://www.youtube.com/watch?v=A-93fbcmytQ">https://www.youtube.com/...</a></td>
      <td>4</td>
    </tr>
    <tr>
      <td>...</td>
      <td></td>
      <td></td>
    </tr>
    <tr>
      <td>Tiktok</td>
      <td><a href="https://www.tiktok.com/@fosudo/video/7372222085759864069">https://www.tiktok.com/@xxx/video/...</a></td>
      <td>4</td>
    </tr>
    <tr>
      <td>...</td>
      <td></td>
      <td></td>
    </tr>
     <tr>
      <td>Reddit</td>
      <td><a href="https://www.reddit.com/r/RayBanStories/comments/1bjf5ni/some_fun_meta_ai_hits_and_misses/">https://www.reddit.com/r/RayBanStories/...</a></td>
      <td>5</td>
    </tr>
    <tr>
      <td>...</td>
      <td></td>
      <td></td>
    </tr>
     <tr>
      <td>Xiaohongshu</td>
      <td><a href="http://xhslink.com/a/9gNBFpEsWGsab">http://xhslink.com/a/...</a></td>
      <td>5</td>
    </tr>
     <tr>
      <td>...</td>
      <td></td>
      <td></td>
    </tr>
     <tr>
      <td>NYTimes</td>
      <td><a href="https://www.nytimes.com/2024/03/28/technology/personaltech/smart-glasses-ray-ban-meta.html">https://www.nytimes.com/...</a></td>
      <td>13</td>
    </tr>
    <tr>
      <td colspan="3" align="center"><i>... and many more ...</i></td>
    </tr>
  </tbody>
</table>


<h3>Subset B</h3>
<ul style="list-style-type: none; padding-left: 0; text-align: left; margin-bottom: 20px;">
   <li><b>Include:</b> 32 conversations (Include Visual, Query, and Answer)</li>
  
</ul>

<p>To get the dataset and generate the JSON file, follow these steps:</p>
<ol style="padding-left: 20px;">
  <li>Download the <code>data.parquet</code> file: <a href="https://drive.google.com/file/d/1KIv2OGelTdgie1F34-S9PpucUm9dYemr/view">Google Drive</a> </li>
  <li>Run the Python script <code>loader.py</code></li>
</ol>
<pre><code># You need to install numpy and pandas first:
# pip3 install numpy pandas
python3 loader.py path/to/the/Subset-B.parquet [--output-json data.json]</code></pre>

> We follow the [crag-mm-2025](https://huggingface.co/crag-mm-2025) dataset format