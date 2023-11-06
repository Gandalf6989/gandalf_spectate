$(function(){

	$('.users').on('click', '.spec', function(){

		let target = $(this).data('spectate');

		let player = $('.spectate').attr('id');

		if (target == player) {
			alert("Magadat nem figyelheted!");
		} else {
			$('.spectate').fadeOut();
			$.post('http://gandalf_spectate/select', JSON.stringify({id: target}));
		}

	});

	$('.header').on('click', '#close', function(){
		$('.spectate').fadeOut();
		$.post('http://gandalf_spectate/quit');
	});

	window.addEventListener('message', function(event){
		if (event.data.type == "show"){
			let data = event.data.data;
			let player = event.data.player;
			$('.spectate').attr('id', player);
			populate(data);
			setTimeout(function(){
				$('.spectate').fadeIn();
			}, 200)
		}
	});

	$(document).keyup(function(e){
		if (e.keyCode == 27){
			$('.spectate').fadeOut();
			$.post('http://gandalf_spectate/close');
		}
	})

});

function searchInput(){
	let input, filter, table, tr, td, i, txtValue;
	input = document.getElementById("searchInput");
	filter = input.value.toUpperCase();
	table = document.querySelector(".table-b");
	tr = table.getElementsByTagName("tr");
	for (i = 0; i < tr.length; i++) {
		td = tr[i];  //td = tr[i].getElementsByTagName("td")[i];
		if (td) {
		txtValue = td.textContent || td.innerText;
		if (txtValue.toUpperCase().indexOf(filter) > -1) {
			tr[i].style.display = "";
		} else {
			tr[i].style.display = "none";
		}
		}       
	}
}

function populate(data){
	$('.users tbody').html('');

	data.sort(function(a, b) {
		let idA = a.id;
		let idB = b.id;
		if (idA < idB)
	        return -1
	    if (idA > idB)
	        return 1
	    return 0
	});

	for (var i = 0; i < data.length; i++) {
		let id = data[i].id;
		let steamName = data[i].steamName;
		let name = data[i].name;
		let job = data[i].job;
		let money = data[i].money;
		let bank = data[i].bank;
		let black = data[i].black;
		let group = data[i].group;
		let players = data[i].players;

		$("#player2").html(players)

		let element =
					'<tr>' +
					'<td class="id"><span class="user-id">' + id + '</span></td>' +
					'<td class="steamName"><span class="user-steamName">' + steamName + '</span></td>' +
					'<td class="group"><span class="user-group">' + group + '</span></td>' +
					'<td class="name"><span class="user-name">' + name + '</span></td>' +
					'<td class="job"><span class="user-job"> ' + job + '</span></td>' +
					'<td class="money"><span class="user-money"> ' + money + "$" + '</span></td>' +
					'<td class="bank"><span class="user-bank"> ' + bank + "$" + '</span></td>' +
					'<td class="black"><span class="user-black"> ' + black + "$" + '</span></td>' +
					'<span class="user-actions">' +
						'<td><button class="spec" data-spectate="' + id + '">Spectate</button></td>' +
					'</span>' +
					'</tr>';
		$('.users table').append(element);
	}
}