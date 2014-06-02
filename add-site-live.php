<?php
include('header.php');
?>

<div class="row-fluid">

<div class="col-md-3">
<div class="panel panel-info">
  <div class="panel-heading">
    <h3 class="panel-title">Active Sites</h3>
  </div>
  <div class="panel-body">

    <?php
    $dir    = '/var/www/vhosts';
    $files1 = scandir($dir);

    foreach ($files1 as $key => $value) {
      switch($key){

        case  0 :
        break;
        case 1:
        break;
        default :
          echo  "<a target='_blank' class='primary' href='http://".$value."''>".$value."</a><br/>";
        break;

      }

    }

?>
  </div>
</div>
</div>
<div class="col-md-9">	
<form class="form-horizontal" method="POST" action="process/site-add.php" >
  <fieldset>
    <legend>Add new website</legend>
    <div class="form-group">
      <label for="sitename" class="col-lg-2 control-label">Site name</label>
      <div class="col-lg-10">
        <input type="text" class="form-control" id="sitename" name ="sitename" placeholder="example: example.com (required)">
      </div>
    </div>
    <div class="form-group">
      <label for="dbname" class="col-lg-2 control-label">Database name</label>
      <div class="col-lg-10">
        <input type="text" class="form-control" id="dbname" name="dbname" placeholder="example: dbname (optional)">
      </div>
    </div>

    <div class="form-group">
      <label for="dbpass" class="col-lg-2 control-label">DB password</label>
      <div class="col-lg-10">
        <input type="password" class="form-control" id="dbpass" name="dbpass" placeholder="(optional)">
        <input type="hidden" name="redirect" value="add-site-live.php">
        <div class="checkbox">
          <label>
            <input type="checkbox" id="ssl" name="ssl"> Enable SSL?
          </label>
        </div>       
      </div>

    </div>

    <div class="form-group">
      <label for="select" class="col-lg-2 control-label">Selects</label>
      <div class="col-lg-10">
        <select multiple="" id="sitetype" name ="sitetype" class="form-control">
          <option value="cs">Coming Soon</option>
          <option value="hb" >Home Base Template</option>
          <option value="wp">Wordpress Template</option>
          <option value="bs">Blank Site</option>          
        </select>
      </div>
    </div>
    <div class="form-group">
      <div class="col-lg-10 col-lg-offset-2">
        <button class="btn btn-danger">Cancel</button>
        <button type="submit" class="btn btn-success">Submit</button>
      </div>
    </div>
  </fieldset>
</form>
</div>

</div>

<?php 
include('footer.php');
?>